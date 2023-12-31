import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroTesting
import RawValueCodableMacros

let isRecording: Bool = false

final class RawValueCodableTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            isRecording: isRecording,
            macros: [
                "RawValueCodable": RawValueCodableMacro.self,
            ]
        ) {
            super.invokeTest()
        }
    }

    func testAccessControl_WhenTypeIsInternal_ShouldGenerateInternalFunctions() throws {
        assertMacro {
            """
            @RawValueCodable
            struct ID: RawRepresentable {
                var rawValue: String
                init(rawValue: String) {
                    self.rawValue = rawValue
                }
            }
            """
        } expansion: {
            """
            struct ID: RawRepresentable {
                var rawValue: String
                init(rawValue: String) {
                    self.rawValue = rawValue
                }

                init(from decoder: Decoder) throws {
                    try self.init(rawValue: decoder.singleValueContainer().decode(RawValue.self))
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }

            extension ID: Swift.Codable {
            }
            """
        }
    }

    func testAccessControl_WhenTypeIsPublic_ShouldGeneratePublicFunctions() throws {
        assertMacro {
            """
            @RawValueCodable
            public struct ID: RawRepresentable {
                public var rawValue: String
                public init(rawValue: String) {
                    self.rawValue = rawValue
                }
            }
            """
        } expansion: {
            """
            public struct ID: RawRepresentable {
                public var rawValue: String
                public init(rawValue: String) {
                    self.rawValue = rawValue
                }

                public init(from decoder: Decoder) throws {
                    try self.init(rawValue: decoder.singleValueContainer().decode(RawValue.self))
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }

            public extension ID: Swift.Codable {
            }
            """
        }
    }

    func testNonRawRepresentable_WhenTypeIsNotRawRepresentable_ShouldDiagnoseWithError() {
        assertMacro {
            """
            @RawValueCodable
            public struct ID {
            }
            """
        } diagnostics: {
            """
            @RawValueCodable
            ╰─ 🛑 @RawValueCodable can only be applied to a type conforming to 'RawRepresentable'
            public struct ID {
            }
            """
        }
    }

    func testEnumRawValue_WhenEnumTypeHasAtLeastOneConformingType_ShouldGenerateFunctionsAsIfTheConformingTypeIsRawValue() {
        assertMacro {
            """
            @RawValueCodable
            enum Texture: String {
                case soft
                case hard
            }
            """
        } expansion: {
            """
            enum Texture: String {
                case soft
                case hard

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let value = try Texture(rawValue: container.decode(RawValue.self))

                    guard let value else {
                        throw DecodingError.dataCorruptedError(
                            in: container,
                            debugDescription: "Unable to decode value of type `RawValue` from data."
                        )
                    }

                    self = value
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }

            extension Texture: Swift.Codable {
            }
            """
        }
    }

    func testCustomRawRepresentableEnum_WhenEnumConformsToRawRepresentable_ShouldGenerateNormalResult() {
        assertMacro {
            """
            @RawValueCodable
            enum Texture: RawRepresentable {
                case soft
                case hard

                var rawValue: String {
                    switch self {
                    case .soft:
                        return "soft"
                    case .hard:
                        return "hard"
                    }
                }

                init?(rawValue: String) {
                    switch rawValue {
                    case "soft":
                        self = .soft
                    case "hard":
                        self = .hard
                    default:
                        return nil
                    }
                }
            }
            """
        } expansion: {
            """
            enum Texture: RawRepresentable {
                case soft
                case hard

                var rawValue: String {
                    switch self {
                    case .soft:
                        return "soft"
                    case .hard:
                        return "hard"
                    }
                }

                init?(rawValue: String) {
                    switch rawValue {
                    case "soft":
                        self = .soft
                    case "hard":
                        self = .hard
                    default:
                        return nil
                    }
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let value = try Texture(rawValue: container.decode(RawValue.self))

                    guard let value else {
                        throw DecodingError.dataCorruptedError(
                            in: container,
                            debugDescription: "Unable to decode value of type `RawValue` from data."
                        )
                    }

                    self = value
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }

            extension Texture: Swift.Codable {
            }
            """
        }
    }
}
