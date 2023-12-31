import Foundation
import RawValueCodable

@RawValueCodable
struct C1: RawRepresentable {
    var rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

@RawValueDecodable
struct C2: RawRepresentable {
    var rawValue: String
    init?(rawValue: String) {
        self.rawValue = rawValue
    }
}

@RawValueCodable
public struct C3: RawRepresentable {
    public var rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

@RawValueCodable
enum C4: String {
    case case1
    case case2
}

@RawValueCodable
enum C5: RawRepresentable {
    case case1
    case case2

    var rawValue: Int {
        switch self {
        case .case1:
            return 1
        case .case2:
            return 2
        }
    }

    init?(rawValue: Int) {
        switch rawValue {
        case 1:
            self = .case1
        case 2:
            self = .case2
        default:
            return nil
        }
    }
}
