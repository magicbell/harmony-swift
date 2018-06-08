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

public class EncodableToDataMapper <T> : Mapper <T, Data> where T: Encodable {
    public override func map(_ from: T) -> Data {
        let data = try! JSONEncoder().encode(from)
        return data
    }
}

public class DataToDecodableMapper <T> : Mapper <Data, T> where T: Decodable {
    public override func map(_ from: Data) -> T {
        let value = try! JSONDecoder().decode(T.self, from: from)
        return value
    }
}

public class EncodableToDecodableMapper <E,D> : Mapper <E, D> where D: Decodable, E: Encodable {
    public override func map(_ from: E) -> D {
        let data = try! JSONEncoder().encode(from)
        let value = try! JSONDecoder().decode(D.self, from: data)
        return value
    }
}
