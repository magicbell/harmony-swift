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
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import MJCocoaCore

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
// MARK: -- Future to MJFuture --
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //

public extension Future where T : AnyObject {
    public func toMJFuture() -> MJFuture<T> {
        let future = MJFuture<T>()
        resolve(success: {value in
            future.set(value)
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T : AnyObject {
    public func toMJFuture<K>() -> MJFuture<K> where T==K? {
        let future = MJFuture<K>()
        resolve(success: {value in
            future.set(value)
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == String {
    public func toMJFuture() -> MJFuture<NSString> {
        let future = MJFuture<NSString>()
        resolve(success: {value in
            future.set(value as NSString)
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == String? {
    public func toMJFuture() -> MJFuture<NSString> {
        let future = MJFuture<NSString>()
        resolve(success: {value in
            future.set(value as NSString?)
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == Date {
    public func toMJFuture() -> MJFuture<NSDate> {
        let future = MJFuture<NSDate>()
        resolve(success: {value in
            future.set(value as NSDate)
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == Date? {
    public func toMJFuture() -> MJFuture<NSDate> {
        let future = MJFuture<NSDate>()
        resolve(success: {value in
            future.set(value as NSDate?)
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == URL {
    public func toMJFuture() -> MJFuture<NSURL> {
        let future = MJFuture<NSURL>()
        resolve(success: {value in
            future.set(value as NSURL)
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == URL? {
    public func toMJFuture() -> MJFuture<NSURL> {
        let future = MJFuture<NSURL>()
        resolve(success: {value in
            future.set(value as NSURL?)
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == Data {
    public func toMJFuture() -> MJFuture<NSData> {
        let future = MJFuture<NSData>()
        resolve(success: {value in
            future.set(value as NSData)
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == Data? {
    public func toMJFuture() -> MJFuture<NSData> {
        let future = MJFuture<NSData>()
        resolve(success: {value in
            future.set(value as NSData?)
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == Bool {
    public func toMJFuture() -> MJFuture<NSNumber> {
        let future = MJFuture<NSNumber>()
        resolve(success: {value in
            future.set(NSNumber(value: value))
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == Bool? {
    public func toMJFuture() -> MJFuture<NSNumber> {
        let future = MJFuture<NSNumber>()
        resolve(success: {value in
            if let value = value {
                future.set(NSNumber(value: value))
            } else {
                future.set(nil)
            }
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == UInt {
    public func toMJFuture() -> MJFuture<NSNumber> {
        let future = MJFuture<NSNumber>()
        resolve(success: {value in
            future.set(NSNumber(value: value))
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == UInt? {
    public func toMJFuture() -> MJFuture<NSNumber> {
        let future = MJFuture<NSNumber>()
        resolve(success: {value in
            if let value = value {
                future.set(NSNumber(value: value))
            } else {
                future.set(nil)
            }
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == Int {
    public func toMJFuture() -> MJFuture<NSNumber> {
        let future = MJFuture<NSNumber>()
        self.resolve(success: {(value) in
            future.set(NSNumber(value: value))
        }, failure: { (error) in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == Int? {
    public func toMJFuture() -> MJFuture<NSNumber> {
        let future = MJFuture<NSNumber>()
        resolve(success: {value in
            if let value = value {
                future.set(NSNumber(value: value))
            } else {
                future.set(nil)
            }
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == Float {
    public func toMJFuture() -> MJFuture<NSNumber> {
        let future = MJFuture<NSNumber>()
        self.resolve(success: {(value) in
            future.set(NSNumber(value: value))
        }, failure: { (error) in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == Float? {
    public func toMJFuture() -> MJFuture<NSNumber> {
        let future = MJFuture<NSNumber>()
        resolve(success: {value in
            if let value = value {
                future.set(NSNumber(value: value))
            } else {
                future.set(nil)
            }
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == Double {
    public func toMJFuture() -> MJFuture<NSNumber> {
        let future = MJFuture<NSNumber>()
        self.resolve(success: {(value) in
            future.set(NSNumber(value: value))
        }, failure: { (error) in
            future.set(error)
        })
        return future
    }
}

public extension Future where T == Double? {
    public func toMJFuture() -> MJFuture<NSNumber> {
        let future = MJFuture<NSNumber>()
        resolve(success: {value in
            if let value = value {
                future.set(NSNumber(value: value))
            } else {
                future.set(nil)
            }
        }, failure: { error in
            future.set(error)
        })
        return future
    }
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
// MARK: -- MJFuture to Future --
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //

public extension Future {
    public convenience init<K>(mjfuture: MJFuture<K>) where T==K? {
        if mjfuture.reactive {
            fatalError("Can't link a reactive MJFuture<T> to a Future<T>. Use Observable<T> instead.")
        }
        self.init() { resolver in
            mjfuture.then { value in
                resolver.set(value)
                }.fail { error in
                resolver.set(error)
            }
        }
    }
}

public extension Future where T == String? {
    public convenience init(mjfuture: MJFuture<NSString>) {
        if mjfuture.reactive {
            fatalError("Can't link a reactive MJFuture<T> to a Future<T>. Use Observable<T> instead.")
        }
        self.init() { resolver in
            mjfuture.then { value in
                resolver.set(value as String?)
                }.fail { error in
                 resolver.set(error)
            }
        }
    }
}

public extension Future where T == Date? {
    public convenience init(mjfuture: MJFuture<NSDate>) {
        if mjfuture.reactive {
            fatalError("Can't link a reactive MJFuture<T> to a Future<T>. Use Observable<T> instead.")
        }
        self.init() { resolver in
            mjfuture.then { value in
                resolver.set(value as Date?)
                }.fail { error in
                    resolver.set(error)
            }
        }
    }
}

public extension Future where T == URL? {
    public convenience init(mjfuture: MJFuture<NSURL>) {
        if mjfuture.reactive {
            fatalError("Can't link a reactive MJFuture<T> to a Future<T>. Use Observable<T> instead.")
        }
        self.init() { resolver in
            mjfuture.then { value in
                resolver.set(value as URL?)
                }.fail { error in
                    resolver.set(error)
            }
        }
    }
}

public extension Future where T == Data? {
    public convenience init(mjfuture: MJFuture<NSData>) {
        if mjfuture.reactive {
            fatalError("Can't link a reactive MJFuture<T> to a Future<T>. Use Observable<T> instead.")
        }
        self.init() { resolver in
            mjfuture.then { value in
                resolver.set(value as Data?)
                }.fail { error in
                    resolver.set(error)
            }
        }
    }
}

public extension Future where T == Bool? {
    public convenience init(mjfuture: MJFuture<NSNumber>) {
        if mjfuture.reactive {
            fatalError("Can't link a reactive MJFuture<T> to a Future<T>. Use Observable<T> instead.")
        }
        self.init() { resolver in
            mjfuture.then { value in
                let value = value?.boolValue
                resolver.set(value)
                }.fail { error in
                    resolver.set(error)
            }
        }
    }
}

public extension Future where T == Int? {
    public convenience init(mjfuture: MJFuture<NSNumber>) {
        if mjfuture.reactive {
            fatalError("Can't link a reactive MJFuture<T> to a Future<T>. Use Observable<T> instead.")
        }
        self.init() { resolver in
            mjfuture.then { value in
                let value = value?.intValue
                resolver.set(value)
                }.fail { error in
                    resolver.set(error)
            }
        }
    }
}

public extension Future where T == Float? {
    public convenience init(mjfuture: MJFuture<NSNumber>) {
        if mjfuture.reactive {
            fatalError("Can't link a reactive MJFuture<T> to a Future<T>. Use Observable<T> instead.")
        }
        self.init() { resolver in
            mjfuture.then { value in
                let value = value?.floatValue
                resolver.set(value)
                }.fail { error in
                    resolver.set(error)
            }
        }
    }
}

public extension Future where T == Double? {
    public convenience init(mjfuture: MJFuture<NSNumber>) {
        if mjfuture.reactive {
            fatalError("Can't link a reactive MJFuture<T> to a Future<T>. Use Observable<T> instead.")
        }
        self.init() { resolver in
            mjfuture.then { value in
                let value = value?.doubleValue
                resolver.set(value)
                }.fail { error in
                    resolver.set(error)
            }
        }
    }
}



// -- -- -- -- -- -- -- - -- -- -- -- -- //
// MARK: Extension on MJFuture
// -- -- -- -- -- -- -- - -- -- -- -- -- //

public extension MJFuture where T == NSString {
    public func toFuture() -> Future<String?> {
        return Future(mjfuture:self)
    }
}

public extension MJFuture where T == NSURL {
    public func toFuture() -> Future<URL?> {
        return Future(mjfuture:self)
    }
}

public extension MJFuture where T == NSDate {
    public func toFuture() -> Future<Date?> {
        return Future(mjfuture:self)
    }
}

public extension MJFuture where T == NSData {
    public func toFuture() -> Future<Data?> {
        return Future(mjfuture:self)
    }
}

