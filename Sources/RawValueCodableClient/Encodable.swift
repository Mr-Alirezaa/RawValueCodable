import Foundation
import RawValueCodable

@RawValueEncodable
struct E1: RawRepresentable {
    var rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

@RawValueEncodable
public struct E2: RawRepresentable {
    public var rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

@RawValueEncodable
enum E3: String {
    case case1
    case case2
}

@RawValueEncodable
enum E4: RawRepresentable {
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
