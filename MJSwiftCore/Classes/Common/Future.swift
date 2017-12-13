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

/// Future states
public enum FutureState {
    case blank
    case waitingBlock
    case waitingValueOrError
    case sent
    
    var localizedDescription: String {
        switch (self) {
        case .blank:
            return "Blank: empty future"
        case .waitingBlock:
            return "Waiting for Block: value or error is already set and future is waiting for a then closure."
        case .waitingValueOrError:
            return "Waiting for Value or Error: then closure is already set and future is waiting for a value or error."
        case .sent:
            return "Sent: future has already sent the value or error to the then closure."
        }
    }
}

/// Observers must implement this protocol
public protocol FutureObserver : AnyObject {
    func didSendValue<T>(_ value: T?)
    func didSendError(_ error: Error)
    func didCompleteFuture<T>(_ future: Future<T>)
}

private enum FutureError: Error {
    case valueAlreadySet
    case errorAlreadySet
    case thenAlreadySet
    case alreadySent
    
    var localizedDescription: String {
        switch (self) {
        case .valueAlreadySet:
            return "Value already set: cannot set a new value once is already set."
        case .errorAlreadySet:
            return "Error already set: cannot set a new error once is already set."
        case .thenAlreadySet:
            return "Then already set: cannot set a new then closure once is already set."
        case .alreadySent:
            return "Future is already sent."
        }
    }
}

/// Future class. Wrapper of an optional value of type T or an error.
public class Future<T> {
    
    /// The future state
    public private(set) var state: FutureState = .blank
    
    /// The optional value
    public private(set) var value: T?
    
    /// The error
    public private(set) var error: Error?
    
    private var success: ((_ value: T?) -> Void)?
    private var failure: ((_ error: Error) -> Void)?
    private var onContentSet: ((inout T?, inout Error?) -> Void)?
    private var isValueNil: Bool = false
    private var queue: DispatchQueue?
    private var semaphore: DispatchSemaphore?
    private let observers = NSHashTable<AnyObject>.weakObjects()
    
    /// Default initializer
    public init() { }
    
    /// Value initializer
    public init(_ value: T?) {
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
    public init(_ closure: @escaping (_ future: Future<T>) -> Void) {
        closure(self)
    }
    
    /// Sets the future value
    public func set(_ value: T?) {
        if self.value != nil || isValueNil {
            fatalError(FutureError.valueAlreadySet.localizedDescription)
        }
        if value == nil {
            isValueNil = true
        }
        self.value = value
        for observer in observers.allObjects {
            (observer as! FutureObserver).didSendValue(value)
        }
        update()
    }
    
    /// Sets the future error
    public func set(_ error: Error) {
        if self.error != nil {
            fatalError(FutureError.errorAlreadySet.localizedDescription)
        }
        self.error = error
        for observer in observers.allObjects {
            (observer as! FutureObserver).didSendError(error)
        }
        update()
    }
    
    /// Sets the future with another future
    public func set(_ future: Future<T>) {
        future.then(success: { (value) in
            self.set(value)
        }, failure: { (error) in
            self.set(error)
        })
    }
    
    /// Sets both future and value together. If error, the error is set, otherwise the optional value is set.
    public func set(value: T?, error: Error?) {
        if let error = error {
            set(error)
        } else {
            set(value)
        }
    }
    
    /// Closure called right after content is set, without waiting the then closure.
    /// Note that multiple calls to this method are discouraged, resulting with only one onContentSet closure being called.
    ///
    /// - Parameter closure: The code to be executed
    public func onSet(_ closure: @escaping () -> Void){
        switch state {
        case .waitingBlock, .sent:
            closure()
        case .blank, .waitingValueOrError:
            onContentSet = { (_,_) in
                closure()
            }
        }
    }
    
    /// Closure called right after content is set, without waiting the then closure.
    /// Note that multiple calls to this method are discouraged, resulting with only one onContentSet closure being called.
    ///
    /// - Parameter closure: The code to be executed
    /// - Returns: The self instance
    public func onSet(_ closure: @escaping (inout T?, inout Error?) -> Void) {
        switch state {
        case .waitingBlock:
            closure(&value, &error)
        case .blank:
            onContentSet = closure
        case .waitingValueOrError:
            onContentSet = closure
        case .sent:
            closure(&value, &error)
        }
    }
    
    /// Then closure executed in the given queue
    ///
    /// - Parameter queue: The dispatch queue to call the then closure
    /// - Returns: The self instance
    public func inQueue(_ queue: DispatchQueue) -> Future<T> {
        self.queue = queue
        return self
    }
    
    /// Then closure executed in the main queue
    public func inMainQueue() -> Future<T> {
        self.queue = DispatchQueue.main
        return self
    }
    
    /// Synchronous then
    public func then() -> (T?, Error?) {
        switch state {
        case .waitingBlock:
            state = .sent
            return (value, error)
        case .blank:
            semaphore = DispatchSemaphore(value: 0)
            DispatchSemaphore.wait(semaphore!)()
            return then()
        case .waitingValueOrError:
            fatalError(FutureError.thenAlreadySet.localizedDescription)
        case .sent:
            fatalError(FutureError.alreadySent.localizedDescription)
        }
    }
    
    /// Then closure: delivers the optional value or the error
    public func then(success: @escaping (_ value: T?) -> Void, failure: @escaping (_ error: Error) -> Void) {
        if self.success != nil || self.failure != nil {
            fatalError(FutureError.thenAlreadySet.localizedDescription)
        }
        self.success = success
        self.failure = failure
        update()
    }
    
    /// Adds an observer
    public func addObserver(_ observer: FutureObserver) {
        observers.add(observer)
        if state == .sent {
            observer.didCompleteFuture(self)
        }
    }
    
    /// Removes an observer
    public func removeObserver(_ observer: FutureObserver) {
        observers.remove(observer)
    }

    private func update() {
        switch state {
        case .sent:
            fatalError(FutureError.alreadySent.localizedDescription)
        case .blank:
            // Waiting for either value||error , or the then block.
            if value != nil || error != nil {
                state = .waitingBlock
                if let onContentSet = onContentSet {
                    onContentSet(&value, &error)
                    self.onContentSet = nil
                }
                if let semaphore = semaphore {
                    DispatchSemaphore.signal(semaphore)()
                }
            } else if (success != nil) {
                state = .waitingValueOrError
            }
        case .waitingBlock:
            if success != nil {
                send()
                state = .sent
            }
        case .waitingValueOrError:
            if (value != nil || isValueNil) || error != nil {
                if let onContentSet = onContentSet {
                    onContentSet(&value, &error)
                    self.onContentSet = nil
                }
                send()
                state = .sent
            }
        }
    }
    
    private func send() {
        if let queue = queue {
            let success = self.success!
            let failure = self.failure!
            let error = self.error
            let value = self.value
            queue.async {
                if let error = error {
                    failure(error)
                } else {
                    success(value)
                }
            }
        } else {
            if let error = error {
                failure!(error)
            } else {
                success!(value)
            }
        }
        for observer in observers.allObjects {
            (observer as! FutureObserver).didCompleteFuture(self)
        }
        self.success = nil
        self.failure = nil
    }
}

// MARK: Future Funtional Programming

/// Functional programming extension
public extension Future {
        
    /// Mappes the value and return a new future with the value mapped
    public func map<K>(_ transform: @escaping (T) -> K) -> Future<K> {
        return Future<K> { future in
            self.then(success: { (value) in
                if value != nil {
                    future.set(transform(value!))
                } else {
                    future.set(nil)
                }
            }, failure: { (error) in
                future.set(error)
            })
        }
    }
    
    /// Mappes the error and return a new future with the error mapped
    public func mapError(_ transform: @escaping (_ error: Error) -> Error) -> Future<T> {
        return Future<T> { future in
            self.then(success: { (value) in
                future.set(value)
            }, failure: { (error) in
                future.set(transform(error))
            })
        }
    }
    
    /// Intercepts the value if success and returns a new future of a mapped type to be chained
    public func flatMap<K>(_ closure: @escaping (_ value: T) -> Future<K>) -> Future<K> {
        return Future<K> { future in
            self.then(success: { (value) in
                if let value = value {
                    future.set(closure(value))
                } else {
                    future.set(nil)
                }
            }, failure: { (error) in
                future.set(error)
            })
        }
    }
    
    /// Intercepts the error (if available) and returns a new future of type T
    public func recover(_ closure: @escaping (_ error: Error) -> Future<T>) -> Future<T> {
        return Future<T> { future in
            self.then(success: { (value) in
                future.set(value)
            }, failure: { (error) in
                future.set(closure(error))
            })
        }
    }
    
    /// Intercepts the then closure and returns a future containing the same result
    public func andThen(success: @escaping (_ value: T?) -> Void = { value in }, failure: @escaping (_ error: Error) -> Void = { error in }) -> Future<T> {
        return Future<T> { future in
            self.then(success: { (value) in
                success(value)
                future.set(value)
            }, failure: { (error) in
                failure(error)
                future.set(error)
            })
        }
    }
    
    @discardableResult
    public func onCompletion(_ closure: @escaping () -> Void) -> Future<T> {
        return Future<T> { future in
            self.then(success: { (value) in
                closure()
                future.set(value)
            }, failure: { (error) in
                closure()
                future.set(error)
            })
        }
    }
    
    /// Filters the value and allows to exchange it in an error
    public func filter(_ closure: @escaping (_ value: T?) -> Error?) -> Future<T> {
        return Future<T> { future in
            self.then(success: { value in
                if let error = closure(value) {
                    future.set(error)
                } else {
                    future.set(value)
                }
            }, failure: { error in
                future.set(error)
            })
        }
    }
    
    /// Creates a new future that holds the tupple of results
    public func zip<K>(_ futureK: Future<K>) -> Future<(T?,K?)> {
        return self.flatMap { valueT in
            return futureK.map({ valueK in
                return (valueT, valueK)
            })
        }
    }
    
    /// Creates a new future that holds the tupple of results
    public func zip<K,L>(_ futureK: Future<K>, _ futureL: Future<L>) -> Future<(T?,K?,L?)> {
        return self.zip(futureK).flatMap { valueTK in
            return futureL.map({ valueL in
                return (valueTK.0, valueTK.1, valueL)
            })
        }
    }
    
    /// Creates a new future that holds the tupple of results
    public func zip<K,L,M>(_ futureK: Future<K>, _ futureL: Future<L>, _ futureM: Future<M>) -> Future<(T?,K?,L?,M?)> {
        return self.zip(futureK, futureL).flatMap { valueTKL in
            return futureM.map({ valueM in
                return (valueTKL.0, valueTKL.1, valueTKL.2, valueM)
            })
        }
    }
    
    /// Creates a new future from self
    public func toFuture() -> Future<T> {
        return Future(self)
    }
}

/// Operator + overriding
public func +<T,K>(left: Future<T>, right: Future<K>) -> Future<(T?,K?)> {
    return left.zip(right)
}

precedencegroup MapPrecedance {
    associativity: left
}
infix operator <^> : MapPrecedance

/// Map operator
public func <^><T,K>(future: Future<T>, map: @escaping (T) -> K) -> Future<K> {
    return future.map { value in map(value) }
}

/// To String extension
extension Future : CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch state {
        case .blank:
            return "Empty future. Waiting for value, error and then closure."
        case .waitingBlock:
            if error != nil {
                return "Future waiting for then closure and error set to: \(error!)"
            } else {
                if value != nil {
                    return "Future waiting for then closure and value set to nil."
                } else {
                    return "Future waiting for then closure and value set to: \(value!)"
                }
            }
        case .waitingValueOrError:
            return "Future then closure set. Waiting for value or error."
        case .sent:
            if error != nil {
                return "Future sent with error: \(error!)"
            } else {
                if value != nil {
                    return "Future sent with nil value."
                } else {
                    return "Future sent with value: \(value!)"
                }
            }
        }
    }
    public var debugDescription: String {
        return description
    }
}
