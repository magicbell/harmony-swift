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
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

extension Operation {
    /// - network: Data stream will only use network
    public static let network = Operation(rawValue: "network")
    /// - networkSync: Data stream will use network and sync with storage if needed
    public static let networkSync = Operation(rawValue: "networkSync")
    /// - storage: Data stream will only use storage
    public static let storage = Operation(rawValue: "storage")
    /// - storageSync: Data stream will use storage and sync with network if needed
    public static let storageSync = Operation(rawValue: "storageSync")
}

///
/// Generic DataProvider implementation for network an storage operations
///
public class NetworkStorageRepository<T> : Repository<T>  {
    
    private let network: DataSource<T>
    private let storage: DataSource<T>
    
    public init(network: DataSource<T>, storage: DataSource<T>) {
        self.network = network
        self.storage = storage
    }
    
    public override func get(_ query: Query, operation: Operation = .storageSync) -> Future<T> {
        return { () -> Future<T> in
            switch operation {
            case .network:
                return network.get(query)
            case .storage:
                return storage.get(query)
            case .networkSync:
                return network.get(query).flatMap { entity in
                    return self.storage.put(entity, in: query)
                }
            case .storageSync:
                return storage.get(query).recover { error in
                    switch error {
                    case is CoreError.NotValid, is CoreError.NotFound:
                        return self.get(query, operation: .networkSync)
                    default:
                        return Future(error)
                    }
                }
            default:
                return super.get(query, operation: operation)
            }
            }()
    }
    
    public override func getAll(_ query: Query, operation: Operation = .storageSync) -> Future<[T]> {
        return { () -> Future<[T]> in
            switch operation {
            case .network:
                return network.getAll(query)
            case .storage:
                return storage.getAll(query)
            case .networkSync:
                return network.getAll(query).flatMap { entities in
                    return self.storage.putAll(entities, in: query)
                }
            case .storageSync:
                return storage.getAll(query).recover { error in
                    switch error {
                    case is CoreError.NotValid, is CoreError.NotFound:
                        return self.getAll(query, operation: .networkSync)
                    default:
                        return Future(error)
                    }
                }
            default:
                return super.getAll(query, operation: operation)
            }
            }()
    }
    
    @discardableResult
    public override func put(_ value: T?, in query: Query, operation: Operation = .networkSync) -> Future<T> {
        return { () -> Future<T> in
            switch operation {
            case .network:
                return network.put(value, in: query)
            case .storage:
                return storage.put(value, in: query)
            case .networkSync:
                return network.put(value, in: query).flatMap { value in
                    return self.storage.put(value, in: query)
                }
            case .storageSync:
                return storage.put(value, in: query).flatMap { value in
                    return self.network.put(value, in: query)
                }
            default:
                return super.put(value, in: query, operation: operation)
            }
            }()
    }
    
    @discardableResult
    public override func putAll(_ array: [T], in query: Query, operation: Operation = .networkSync) -> Future<[T]> {
        return { () -> Future<[T]> in
            switch operation {
            case .network:
                return network.putAll(array, in: query)
            case .storage:
                return storage.putAll(array, in: query)
            case .networkSync:
                return network.putAll(array, in: query).flatMap { array in
                    return self.storage.putAll(array, in: query)
                }
            case .storageSync:
                return storage.putAll(array, in: query).flatMap { array in
                    return self.network.putAll(array, in: query)
                }
            default:
                return super.putAll(array, in: query, operation: operation)
            }
            }()
    }
    
    @discardableResult
    public override func delete(_ query: Query, operation: Operation = .networkSync) -> Future<Void> {
        return { () -> Future<Void> in
            switch operation {
            case .network:
                return network.delete(query)
            case .storage:
                return storage.delete(query)
            case .networkSync:
                return network.delete(query).flatMap {
                    return self.storage.delete(query)
                }
            case .storageSync:
                return storage.delete(query).flatMap {
                    return self.network.delete(query)
                }
            default:
                return super.delete(query, operation: operation)
            }
            }()
    }
    
    @discardableResult
    public override func deleteAll(_ query: Query, operation: Operation = .networkSync) -> Future<Void> {
        return { () -> Future<Void> in
            switch operation {
            case .network:
                return network.deleteAll(query)
            case .storage:
                return storage.deleteAll(query)
            case .networkSync:
                return network.deleteAll(query).flatMap {
                    return self.storage.deleteAll(query)
                }
            case .storageSync:
                return storage.deleteAll(query).flatMap {
                    return self.network.deleteAll(query)
                }
            default:
                return super.deleteAll(query, operation: operation)
            }
            }()
    }
}
