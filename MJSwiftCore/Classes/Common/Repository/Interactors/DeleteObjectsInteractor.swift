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
/// Generic delete objects interactor
///
public struct DeleteObjectsInteractor <T> {

    private let executor : Executor
    private let repository: Repository<T>
    
    public init(_ executor: Executor, _ repository: Repository<T>) {
        self.executor = executor
        self.repository = repository
    }
    
    public func execute(objects: [T] = [], query: Query = BlankQuery(), operation: Operation = .blank) -> Future<Bool> {
        return executor.submit { future in
            future.set(self.repository.deleteAll(objects, in: query, operation: operation))
        }
    }
    
    public func execute<K>(objects: [T] = [], forId id: K, operation: Operation = .blank) -> Future<Bool> where K:Hashable {
        return executor.submit { future in
            future.set(self.repository.deleteAll(objects, forId: id, operation: operation))
        }
    }
}