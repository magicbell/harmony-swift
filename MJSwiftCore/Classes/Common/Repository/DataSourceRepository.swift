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

///
/// Single data source repository.
/// All repository methods are directly forwarded to a single data source.
/// Operation parameter is not used in any case.
///
public class GetDataSourceRepository<D: GetDataSource,T> : GetRepository where D.T == T {
    
    private let dataSource : D
    
    /// Default initializer
    ///
    /// - Parameters:
    ///   - dataSource: The contained data source
    public init(_ dataSource: D) {
        self.dataSource = dataSource
    }
    
    public func get(_ query: Query, operation: Operation = BlankOperation()) -> Future<T> {
        return dataSource.get(query)
    }
    
    public func getAll(_ query: Query, operation: Operation = BlankOperation()) -> Future<[T]> {
        return dataSource.getAll(query)
    }
}

extension GetDataSource {
    /// Creates a single data source repository from a data source
    ///
    /// - Returns: A SingleGetDataSourceRepository repository
    public func toGetRepository() -> AnyGetRepository<T> {
        return GetDataSourceRepository(self).asAnyGetRepository()
    }
}

///
/// Single data source repository.
/// All repository methods are directly forwarded to a single data source.
/// Operation parameter is not used in any case.
///
public class PutDataSourceRepository<D: PutDataSource,T> : PutRepository where D.T == T {
    
    private let dataSource : D
    
    /// Default initializer
    ///
    /// - Parameters:
    ///   - dataSource: The contained data source
    public init(_ dataSource: D) {
        self.dataSource = dataSource
    }
    
    @discardableResult
    public func put(_ value: T?, in query: Query, operation: Operation = BlankOperation()) -> Future<T> {
        return dataSource.put(value, in: query)
    }
    
    @discardableResult
    public func putAll(_ array: [T], in query: Query, operation: Operation = BlankOperation()) -> Future<[T]> {
        return dataSource.putAll(array, in: query)
    }
}

extension PutDataSource {
    /// Creates a single data source repository from a data source
    ///
    /// - Returns: A SinglePutDataSourceRepository repository
    public func toPutRepository() -> AnyPutRepository<T> {
        return PutDataSourceRepository(self).asAnyPutRepository()
    }
}

///
/// Single data source repository.
/// All repository methods are directly forwarded to a single data source.
/// Operation parameter is not used in any case.
///
public class DeleteDataSourceRepository<D: DeleteDataSource,T> : DeleteRepository where D.T == T {
    
    private let dataSource : D
    
    /// Default initializer
    ///
    /// - Parameters:
    ///   - dataSource: The contained data source
    public init(_ dataSource: D) {
        self.dataSource = dataSource
    }

    @discardableResult
    public func delete(_ query: Query, operation: Operation = BlankOperation()) -> Future<Void> {
        return dataSource.delete(query)
    }
    
    @discardableResult
    public func deleteAll(_ query: Query, operation: Operation = BlankOperation()) -> Future<Void> {
        return dataSource.deleteAll(query)
    }
}

extension DeleteDataSource {
    /// Creates a single data source repository from a data source
    ///
    /// - Returns: A SingleDeleteDataSourceRepository repository
    public func toDeleteRepository() -> AnyDeleteRepository<T> {
        return DeleteDataSourceRepository(self).asAnyDeleteRepository()
    }
}

///
/// Single data source repository.
/// All repository methods are directly forwarded to a single data source.
/// Operation parameter is not used in any case.
///
public class DataSourceRepository<Get: GetDataSource,Put: PutDataSource,Delete: DeleteDataSource,T> : Repository where Get.T == T, Put.T == T, Delete.T == T {
    
    private let getDataSource : Get?
    private let putDataSource : Put?
    private let deleteDataSource : Delete?
    
    /// Main initializer
    ///
    /// - Parameters:
    ///   - getDataSource: The get data source
    ///   - putDataSource: The put data source
    ///   - deleteDataSource: The delete data source
    public init(get getDataSource: Get? = nil, put putDataSource: Put? = nil, delete deleteDataSource: Delete? = nil) {
        self.getDataSource = getDataSource
        self.putDataSource = putDataSource
        self.deleteDataSource = deleteDataSource
    }
    
    public func get(_ query: Query, operation: Operation = BlankOperation()) -> Future<T> {
        guard let dataSource = getDataSource else {
            fatalError()
        }
        return dataSource.get(query)
    }
    
    public func getAll(_ query: Query, operation: Operation = BlankOperation()) -> Future<[T]> {
        guard let dataSource = getDataSource else {
            fatalError()
        }
        return dataSource.getAll(query)
    }
    
    @discardableResult
    public func put(_ value: T?, in query: Query, operation: Operation = BlankOperation()) -> Future<T> {
        guard let dataSource = putDataSource else {
            fatalError()
        }
        return dataSource.put(value, in: query)
    }
    
    @discardableResult
    public func putAll(_ array: [T], in query: Query, operation: Operation = BlankOperation()) -> Future<[T]> {
        guard let dataSource = putDataSource else {
            fatalError()
        }
        return dataSource.putAll(array, in: query)
    }
    
    @discardableResult
    public func delete(_ query: Query, operation: Operation = BlankOperation()) -> Future<Void> {
        guard let dataSource = deleteDataSource else {
            fatalError()
        }
        return dataSource.delete(query)
    }
    
    @discardableResult
    public func deleteAll(_ query: Query, operation: Operation = BlankOperation()) -> Future<Void> {
        guard let dataSource = deleteDataSource else {
            fatalError()
        }
        return dataSource.deleteAll(query)
    }
}

extension DataSourceRepository where Get == Put, Get == Delete {
    /// Initializer for a single DataSource
    ///
    /// - Parameter dataSource: The data source
    public convenience init(_ dataSource: Get) {
        self.init(get: dataSource, put: dataSource, delete: dataSource)
    }
}

extension DataSource {
    /// Creates a single data source repository from a data source
    ///
    /// - Returns: A SingleDataSourceRepository repository
    public func toRepository() -> AnyRepository<T> {
        return DataSourceRepository(self).asAnyRepository()
    }
}