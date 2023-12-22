import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(RawValueCodableMacros)
import RawValueCodableMacros
#endif

final class RawValueCodableTests: XCTestCase {
    func testRawValueDecodableMacro() throws {
        #if canImport(RawValueCodableMacros)
        assertMacroExpansion(
            """
            @RawValueDecodable
            struct ID: RawRepresentable {
                var rawValue: String
                init(rawValue: String) {
                    self.rawValue = rawValue
                }
            }
            """,
            expandedSource: """
            struct ID: RawRepresentable {
                var rawValue: String
                init(rawValue: String) {
                    self.rawValue = rawValue
                }

                init(from decoder: Decoder) throws {
                    try self.init(rawValue: decoder.singleValueContainer().decode(RawValue.self))
                }
            }

            extension ID: Decodable {
            }
            """,
            macros: [
                "RawValueDecodable": RawValueDecodableMacro.self
            ]
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif

    }

    func testRawValueEncodableMacro() throws {
        #if canImport(RawValueCodableMacros)
        assertMacroExpansion(
            """
            @RawValueEncodable
            struct ID: RawRepresentable {
                var rawValue: String
                init(rawValue: String) {
                    self.rawValue = rawValue
                }
            }
            """,
            expandedSource: """
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

            extension ID: Encodable {
            }
            """,
            macros: [
                "RawValueEncodable": RawValueEncodableMacro.self
            ]
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRawValueCodableMacro() throws {
        #if canImport(RawValueCodableMacros)
        assertMacroExpansion(
            """
            @RawValueCodable
            struct ID: RawRepresentable {
                var rawValue: String
                init(rawValue: String) {
                    self.rawValue = rawValue
                }
            }
            """,
            expandedSource: """
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

            extension ID: Codable {
            }
            """,
            macros: [
                "RawValueCodable": RawValueCodableMacro.self
            ]
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
