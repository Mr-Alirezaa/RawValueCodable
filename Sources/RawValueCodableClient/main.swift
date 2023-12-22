import RawValueCodable

//@RawValueDecodable
//@RawValueEncodable
struct ID: RawRepresentable {
    var rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
}
