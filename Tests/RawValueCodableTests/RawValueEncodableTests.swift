import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroTesting
import RawValueCodableMacros

final class RawValueEncodableTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            isRecording: isRecording,
            macros: [
                "RawValueEncodable": RawValueEncodableMacro.self,
            ]
        ) {
            super.invokeTest()
        }
    }

    func testAccessControl_WhenTypeIsInternal_ShouldGenerateInternalEncode() throws {
        assertMacro {
            """
            @RawValueEncodable
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

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }

            extension ID: Swift.Encodable {
            }
            """
        }
    }

    func testAccessControl_WhenTypeIsPublic_ShouldGeneratePublicEncode() throws {
        assertMacro {
            """
            @RawValueEncodable
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

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }

            public extension ID: Swift.Encodable {
            }
            """
        }
    }

    func testNonRawRepresentable_WhenTypeIsNotRawRepresentable_ShouldDiagnoseWithError() {
        assertMacro {
            """
            @RawValueEncodable
            public struct ID {
            }
            """
        } diagnostics: {
            """
            @RawValueEncodable
            ╰─ 🛑 @RawValueCodable can only be applied to a type conforming to 'RawRepresentable'
            public struct ID {
            }
            """
        }
    }

    func testCustomRawRepresentableEnum_WhenEnumConformsToRawRepresentable_ShouldGenerateNormalResult() throws {
        assertMacro {
            """
            @RawValueEncodable
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

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }

            extension Texture: Swift.Encodable {
            }
            """
        }
    }
}
