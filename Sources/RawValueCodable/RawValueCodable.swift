@attached(member, names: named(init(from:)))
@attached(extension, conformances: Decodable)
public macro RawValueDecodable() = #externalMacro(
    module: "RawValueCodableMacros",
    type: "RawValueDecodableMacro"
)

@attached(member, names: named(encode(to:)))
@attached(extension, conformances: Encodable)
public macro RawValueEncodable() = #externalMacro(
    module: "RawValueCodableMacros",
    type: "RawValueEncodableMacro"
)

@attached(member, names: named(init(from:)), named(encode(to:)))
@attached(extension, conformances: Codable)
public macro RawValueCodable() = #externalMacro(
    module: "RawValueCodableMacros",
    type: "RawValueCodableMacro"
)
