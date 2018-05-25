//
// Copyright 2017 Mobile Jazz SL
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implOied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

fileprivate struct FutureError : Error {
    let description : String
    init(_ description: String) {
        self.description = description
    }
}

extension FutureError {
    /// Future content has already been set
    fileprivate static let thenAlreadySet = FutureError("Then already set: cannot set a new then closure once is already set.")
    
    /// Future content has already been set
    fileprivate static let alreadySent = FutureError("Future is already sent.")
    
    /// Future content has already been set
    fileprivate static let missingLambda = FutureError("Future cannot be sent as the then clousre hasn't been defined")
}

///
/// A FutureResolver resolves a Future.
///
public struct FutureResolver<T> {
    
    private var future : Future<T>
    
    /// Main initializer
    ///
    /// - Parameter future: The future to resolve
    public init(_ future: Future<T>) {
        self.future = future
    }
    
    /// Sets the future value
    public func set(_ value: T) {
        future.set(value)
    }
    
    /// Sets the future error
    public func set(_ error: Error) {
        future.set(error)
    }
    
    /// Sets the future with another future
    public func set(_ future: Future<T>) {
        self.future.set(future)
    }
    
    /// Sets the future with a value if not error. Either the value or the error must be provided, otherwise a crash will happen.
    /// Note: error is prioritary, and if not error the value will be used.
    public func set(value: T?, error: Error?) {
        future.set(value: value, error: error)
    }
}

extension FutureResolver where T==Void {
    /// Sets the future with a void value
    public func set() {
        future.set()
    }
}


///
/// Future class. Wrapper of a future value of generic type T or an error.
///
public class Future<T> {
    /// Future states
    public enum State {
        case blank
        case waitingThen
        case waitingContent
        case sent
        
        var localizedDescription: String {
            switch (self) {
            case .blank:
                return "Blank: empty future"
            case .waitingThen:
                return "Waiting for Block: value or error is already set and future is waiting for a then closure."
            case .waitingContent:
                return "Waiting for Value or Error: then closure is already set and future is waiting for a value or error."
            case .sent:
                return "Sent: future has already sent the value or error to the then closure."
            }
        }
    }
    
    /// The future state
    public private(set) var state: State = .blank
    
    /// The future's result
    ///
    /// - value: a value was provided
    /// - error: an error was provided
    public indirect enum Result {
        case value(T)
        case error(Error)
        
        /// Returns the value or throws an error if exists
        @discardableResult
        public func get() throws -> T {
            switch self {
            case .value(let v):
                return v
            case .error(let e):
                throw e
            }
        }
        
        // Returns the value or if error, returns nil and sets the error
        @discardableResult
        public func get(error: inout Error?) -> T? {
            switch self {
            case .value(let v):
                return v
            case .error(let e):
                error = e
                return nil
            }
        }
    }
    
    /// The future result. Using _ prefix as the "result" method returns synchronously the result.
    internal var _result : Result? = nil
    
    // Private variables
    private var onContentSet: ((inout T?, inout Error?) -> Void)?
    private var queue: DispatchQueue?
    private var semaphore: DispatchSemaphore?
    private let lock = NSLock()
    private var success: ((_ value: T) -> Void)?
    private var failure: ((_ error: Error) -> Void)?
        
    /// Default initializer
    public init() { }
    
    /// Value initializer
    public init(_ value: T) {
        set(value)
    }
    
    /// Error initializer
    public init(_ error: Error) {
        set(error)
    }
    
    /// Future initializer
    public init(_ future: Future<T>) {
        set(future)
    }
    
    /// Future initializer
    public init(_ closure: (FutureResolver<T>) throws -> Void) {
        do {
            let resolver = FutureResolver(self)
            try closure(resolver)
        } catch (let error) {
            set(error)
        }
    }
    
    /// Future initializer
    public convenience init(_ closure: () throws -> T) {
        do {
            let value = try closure()
            self.init(value)
        } catch (let error) {
            self.init(error)
        }
    }
        
    /// Future initializer
    public convenience init(_ closure: () -> Error) {
        let error = closure()
        self.init(error)
    }
    
    /// Creates a new future from self
    public func toFuture() -> Future<T> {
        return Future(self)
    }
    
    /// Sets the future value
    public func set(_ value: T) {
        set(value: value, error: nil)
    }
    
    /// Sets the future error
    public func set(_ error: Error) {
        set(value: nil, error: error)
    }
    
    /// Sets the future with another future
    public func set(_ future: Future<T>) {
        future.resolve(success: { value in
            self.set(value)
        }, failure: { error in
            self.set(error)
        })
    }
    
    /// Sets the future with a value if not error. Either the value or the error must be provided, otherwise a crash will happen.
    /// Note: error is prioritary, and if not error the value will be used.
    public func set(value: T?, error: Error?) {
        if _result != nil || state == .sent  {
            // Do nothing
            return
        }
        
        var value : T? = value
        var error : Error? = error
        if let onContentSet = onContentSet {
            onContentSet(&value, &error)
            self.onContentSet = nil
        }
        
        lock() {
            if let error = error {
                _result = .error(error)
            } else {
                _result = .value(value!)
            }
            
            if success != nil || failure != nil {
                // Resolve the then closure
                send()
                state = .sent
            } else {
                state = .waitingThen
                if let semaphore = semaphore {
                    semaphore.signal()
                }
            }
        }
    }
    
    /// Clears the stored value and the referenced then closures.
    /// Mainly, resets the state of the future to blank.
    ///
    /// - Returns: The self instance
    @discardableResult
    public func clear() -> Future<T> {
        lock() {
            _result = nil
            success = nil
            failure = nil
            state = .blank
        }
        return self
    }
    
    /// Closure called right after content is set, without waiting the then closure.
    /// Note that multiple calls to this method are discouraged, resulting with only one onContentSet closure being called.
    /// Note too that if the future has already been sent, this closure is not called.
    ///
    /// - Parameter closure: The code to be executed
    public func onSet(_ closure: @escaping () -> Void) {
        onContentSet = { (_,_) in
            closure()
        }
    }
    
    /// Closure called right after content is set, without waiting the then closure.
    /// Multiple calls to this method are discouraged, resulting with only one onContentSet closure being called.
    /// Note too that if the future has already been sent, this closure is not called.
    ///
    /// - Parameter closure: The code to be executed
    public func onSet(_ closure: @escaping (inout T?, inout Error?) -> Void) {
        onContentSet = closure
    }
    
    /// Then closure executed in the given queue
    ///
    /// - Parameter queue: The dispatch queue to call the then closure
    /// - Returns: The self instance
    @discardableResult
    public func on(_ queue: DispatchQueue?) -> Future<T> {
        self.queue = queue
        return self
    }
    
    /// Then closure executed in the main queue
    ///
    /// - Returns: The self instance
    @discardableResult
    public func onMainQueue() -> Future<T> {
        return self.on(DispatchQueue.main)
    }
    
    /// Then closure: delivers the value or the error
    internal func resolve(success: @escaping (T) -> Void = { _ in },
                          failure: @escaping (Error) -> Void = { _ in }) {
        
        if self.success != nil || self.failure != nil {
            fatalError(FutureError.thenAlreadySet.description)
        }
        
        lock() {
            self.success = success
            self.failure = failure
            if _result != nil {
                send()
                state = .sent
            } else {
                state = .waitingContent
            }
        }
    }
    
    /// Deliver the result syncrhonously. This method might block the calling thread.
    /// Note that the result can only be delivered once
    public var result : Result {
        get {
            switch state {
            case .waitingThen:
                state = .sent
                return _result!
            case .blank:
                semaphore = DispatchSemaphore(value: 0)
                semaphore!.wait()
                return self.result
            case .waitingContent:
                fatalError(FutureError.thenAlreadySet.description)
            case .sent:
                fatalError(FutureError.alreadySent.description)
            }
        }
    }
    
    /// Main then method
    @discardableResult
    public func then(_ success: @escaping (T) -> Void) -> Future<T> {
        return Future() { resolver in
            resolve(success: {value in
                success(value)
                resolver.set(value)
            }, failure: { error in
                resolver.set(error)
            })
        }
    }
    
    /// Main fail method
    @discardableResult
    public func fail(_ failure: @escaping (Error) -> Void) -> Future<T> {
        return Future() { resolver in
            resolve(success: {value in
                resolver.set(value)
            }, failure: { error in
                failure(error)
                resolver.set(error)
            })
        }
    }
    
    /// Completes the future (if not completed yet)
    public func complete() {
        lock() {
            if state != .sent {
                state = .sent
                success = nil
                failure = nil
            }
        }
    }
    
    private func send() {
        switch _result! {
        case .error(let error):
            guard let failure = failure else {
                print(FutureError.missingLambda.description)
                return
            }
            if let queue = queue, !(queue == DispatchQueue.main && Thread.isMainThread) {
                queue.async {
                    failure(error)
                }
            } else {
                failure(error)
            }
        case .value(let value):
            guard let success = success else {
                print(FutureError.missingLambda.description)
                return
            }
            if let queue = queue, !(queue == DispatchQueue.main && Thread.isMainThread) {
                queue.async {
                    success(value)
                }
                
            } else {
                success(value)
            }
        }
        
        self.success = nil
        self.failure = nil
    }
    
    // Private lock method
    private func lock(_ closure: () -> Void) {
        lock.lock()
        closure()
        lock.unlock()
    }
}

/// To String extension
extension Future : CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch state {
        case .blank:
            return "Empty future. Waiting for value, error and then closure."
        case .waitingThen:
            switch _result! {
            case .error(let error):
                return "Future waiting for then closure and error set to: \(error)"
            case .value(let value):
                return "Future waiting for then closure and value set to: \(value)"
            }
        case .waitingContent:
            return "Future then closure set. Waiting for value or error."
        case .sent:
            switch _result! {
            case .error(let error):
                return "Future sent with error: \(error)"
            case .value(let value):
                return "Future sent with value: \(value)"
            }
        }
    }
    public var debugDescription: String {
        return description
    }
}

extension Future where T==Void {
    public func set() {
        set(Void())
    }
}
