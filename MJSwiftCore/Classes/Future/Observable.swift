//
// Copyright 2018 Mobile Jazz SL
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

fileprivate struct ObservableError : Error {
    let description : String
    init(_ description: String) {
        self.description = description
    }
}

extension ObservableError {
    /// Observable content has already been set
    fileprivate static let thenAlreadySet = ObservableError("Then already set: cannot set a new then closure once is already set.")
    
    /// Observable content has already been set
    fileprivate static let missingLambda = ObservableError("Observable cannot be sent as the then clousre hasn't been defined")
}

///
/// A ObservableResolver resolves a Observable.
///
public struct ObservableResolver<T> {
    
    private weak var observable : Observable<T>?
    
    /// Main initializer
    ///
    /// - Parameter observable: The observable to resolve
    public init(_ observable: Observable<T>) {
        self.observable = observable
    }
    
    /// Sets the observable value
    public func set(_ value: T) {
        observable?.set(value)
    }
    
    /// Sets the observable error
    public func set(_ error: Error) {
        observable?.set(error)
    }
    
    /// Sets the observable with another observable
    public func set(_ observable: Observable<T>) {
        self.observable?.set(observable)
    }
    
    /// Sets the observable with a value if not error. Either the value or the error must be provided, otherwise a crash will happen.
    /// Note: error is prioritary, and if not error the value will be used.
    public func set(value: T?, error: Error?) {
        observable?.set(value: value, error: error)
    }
}

extension ObservableResolver where T==Void {
    /// Sets the observable with a void value
    public func set() {
        observable?.set()
    }
}

///
/// Observable class. Wrapper of a observable value of generic type T or an error.
///
public class Observable<T> {
    /// Observable states
    public enum State {
        case blank
        case waitingThen
        case waitingContent
        
        var localizedDescription: String {
            switch (self) {
            case .blank:
                return "Blank: empty observable"
            case .waitingThen:
                return "Waiting for Block: value or error is already set and observable is waiting for a then closure."
            case .waitingContent:
                return "Waiting for Value or Error: then closure is already set and observable is waiting for a value or error."
            }
        }
    }
    
    /// The observable state
    public private(set) var state: State = .blank
    
    // A storng reference to the parent observable, when chaining observables
    public private(set) var parent : Any?
    
    /// The observable's result
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
    
    /// The observable result. Using _ prefix as the "result" method returns synchronously the result.
    internal var _result : Result? = nil
    
    // Private variables
    private var onContentSet: ((inout T?, inout Error?) -> Void)?
    private var queue: DispatchQueue?
    private var semaphore: DispatchSemaphore?
    private let lock = NSLock()
    private var success: ((_ value: T) -> Void)?
    private var failure: ((_ error: Error) -> Void)?
    
    /// Returns a hub associated to the current observable
    public private(set) lazy var hub = ObservableHub<T>(self)
    
    /// Default initializer
    public init(parent: Any? = nil) {
        self.parent = parent
    }
    
    /// Value initializer
    public init(_ value: T, parent: Any? = nil) {
        self.parent = parent
        set(value)
    }
    
    /// Error initializer
    public init(_ error: Error, parent: Any? = nil) {
        self.parent = parent
        set(error)
    }
    
    /// Observable initializer
    public init(_ observable: Observable<T>) {
        set(observable)
    }
    
    /// Observable initializer
    public init(parent: Any? = nil, _ closure: (ObservableResolver<T>) throws -> Void) {
        self.parent = parent
        do {
            let resolver = ObservableResolver(self)
            try closure(resolver)
        } catch (let error) {
            set(error)
        }
    }
    
    deinit {
        print("Deinit \(String(describing: type(of: self)))")
    }
        
    /// Observable initializer
    public convenience init(_ closure: () -> Error) {
        let error = closure()
        self.init(error)
    }
    
    /// Creates a new observable from self
    public func toObservable() -> Observable<T> {
        return Observable(self)
    }
    
    /// Sets the observable value
    public func set(_ value: T) {
        set(value: value, error: nil)
    }
    
    /// Sets the observable error
    public func set(_ error: Error) {
        set(value: nil, error: error)
    }
    
    /// Sets the observable with another observable
    public func set(_ observable: Observable<T>) {
        // Current observable retains the incoming observable
        self.parent = observable
        
        // Incoming observable DOES NOT retain the current observable
        observable.resolve(success: { [weak self] value in
            self?.set(value)
            }, failure: { [weak self] error in
                self?.set(error)
        })
    }
    
    /// Sets the observable with a value if not error. Either the value or the error must be provided, otherwise a crash will happen.
    /// Note: error is prioritary, and if not error the value will be used.
    public func set(value: T?, error: Error?) {
        var value : T? = value
        var error : Error? = error
        if let onContentSet = onContentSet {
            onContentSet(&value, &error)
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
            } else {
                state = .waitingThen
                if let semaphore = semaphore {
                    semaphore.signal()
                }
            }
        }
    }
    
    /// Clears the stored value and the referenced then closures.
    /// Mainly, resets the state of the observable to blank.
    ///
    /// - Returns: The self instance
    @discardableResult
    public func clear() -> Observable<T> {
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
    /// Note too that if the observable has already been sent, this closure is not called.
    ///
    /// - Parameter closure: The code to be executed
    public func onSet(_ closure: @escaping () -> Void) {
        onContentSet = { (_,_) in
            closure()
        }
    }
    
    /// Closure called right after content is set, without waiting the then closure.
    /// Multiple calls to this method are discouraged, resulting with only one onContentSet closure being called.
    /// Note too that if the observable has already been sent, this closure is not called.
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
    public func on(_ queue: DispatchQueue?) -> Observable<T> {
        self.queue = queue
        return self
    }
    
    /// Then closure executed in the main queue
    ///
    /// - Returns: The self instance
    @discardableResult
    public func onMainQueue() -> Observable<T> {
        return self.on(DispatchQueue.main)
    }
    
    /// Then closure: delivers the value or the error
    internal func resolve(success: @escaping (T) -> Void = { _ in },
                          failure: @escaping (Error) -> Void = { _ in }) {
        lock() {
            self.success = success
            self.failure = failure
            if _result != nil {
                send()
            } else {
                state = .waitingContent
            }
        }
    }
    
    /// Deliver the result syncrhonously. This method might block the calling thread.
    /// Note that the result can only be delivered once if the observable is not reactive.
    public var result : Result {
        get {
            switch state {
            case .waitingThen:
                return _result!
            case .blank:
                semaphore = DispatchSemaphore(value: 0)
                semaphore!.wait()
                return self.result
            case .waitingContent:
                fatalError(ObservableError.thenAlreadySet.description)
            }
        }
    }
    
    /// Main then method
    @discardableResult
    public func then(_ success: @escaping (T) -> Void) -> Observable<T> {
        return Observable(parent: self) { resolver in
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
    public func fail(_ failure: @escaping (Error) -> Void) -> Observable<T> {
        return Observable(parent: self) { resolver in
            resolve(success: {value in
                resolver.set(value)
            }, failure: { error in
                failure(error)
                resolver.set(error)
            })
        }
    }

    private func send() {
        switch _result! {
        case .error(let error):
            guard let failure = failure else {
                print(ObservableError.missingLambda.description)
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
                print(ObservableError.missingLambda.description)
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
    }
    // Private lock method
    private func lock(_ closure: () -> Void) {
        lock.lock()
        closure()
        lock.unlock()
    }
}


/// To String extension
extension Observable : CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch state {
        case .blank:
            return "Empty observable. Waiting for value, error and then closure."
        case .waitingThen:
            switch _result! {
            case .error(let error):
                return "Observable waiting for then closure and error set to: \(error)"
            case .value(let value):
                return "Observable waiting for then closure and value set to: \(value)"
            }
        case .waitingContent:
            return "Observable then closure set. Waiting for value or error."
        }
    }
    
    public var debugDescription: String {
        return description
    }
}

extension Observable where T==Void {
    public func set() {
        set(Void())
    }
}
