import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroTesting
import RawValueCodableMacros

final class RawValueDecodableTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            isRecording: isRecording,
            macros: [
                "RawValueDecodable": RawValueDecodableMacro.self,
            ]
        ) {
            super.invokeTest()
        }
    }

    func testAccessControl_WhenTypeIsInternal_ShouldGenerateInternalInit() throws {
        assertMacro {
            """
            @RawValueDecodable
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
            }

            extension ID: Swift.Decodable {
            }
            """
        }
    }

    func testNonFailableInitRawValue_WhenInitRawValueIsNonFailable_ShouldGenerateInitializerWithoutFailurePossibility() throws {
        assertMacro {
            """
            @RawValueDecodable
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
            }

            extension ID: Swift.Decodable {
            }
            """
        }
    }

    func testFailableInitRawValue_WhenInitRawValueIsFailable_ShouldGenerateInitializerWithFailurePossibility() throws {
        assertMacro {
            """
            @RawValueDecodable
            struct ID: RawRepresentable {
                var rawValue: String
                init?(rawValue: String) {
                    self.rawValue = rawValue
                }
            }
            """
        } expansion: {
            """
            struct ID: RawRepresentable {
                var rawValue: String
                init?(rawValue: String) {
                    self.rawValue = rawValue
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let value = try ID(rawValue: container.decode(RawValue.self))

                    guard let value else {
                        throw DecodingError.dataCorruptedError(
                            in: container,
                            debugDescription: "Unable to decode value of type `RawValue` from data."
                        )
                    }

                    self = value
                }
            }

            extension ID: Swift.Decodable {
            }
            """
        }
    }

    func testAccessControl_WhenTypeIsPublic_ShouldGeneratePublicInit() throws {
        assertMacro {
            """
            @RawValueDecodable
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
            }

            public extension ID: Swift.Decodable {
            }
            """
        }
    }

    func testNonRawRepresentable_WhenTypeIsNotRawRepresentable_ShouldDiagnoseWithError() {
        assertMacro {
            """
            @RawValueDecodable
            public struct ID {
            }
            """
        } diagnostics: {
            """
            @RawValueDecodable
            ╰─ 🛑 @RawValueDecodable can only be applied to a type conforming to 'RawRepresentable'
            public struct ID {
            }
            """
        }
    }

    func testCustomRawRepresentableEnum_WhenEnumConformsToRawRepresentable_ShouldGenerateNormalResult() throws {
        assertMacro {
            """
            @RawValueDecodable
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
            }

            extension Texture: Swift.Decodable {
            }
            """
        }
    }
}
