import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct RawValueDecodableMacro: RawValueCodingMacro {
    static let macroName = "RawValueDecodable"

    static let conformanceName = "Decodable"
    static var qualifiedConformanceName: String { "Swift.\(Self.conformanceName)" }
    static var conformanceNames: [String] { [Self.conformanceName, Self.qualifiedConformanceName] }

    static let rawRepresentable = "RawRepresentable"
    static var qualifiedRawRepresentable = "Swift.\(rawRepresentable)"
    static var rawRepresentableNames = [rawRepresentable, qualifiedRawRepresentable]
}

extension RawValueDecodableMacro: MemberMacro, ExtensionMacro {
    typealias Diagnostic = MacroDiagnostic<Self>

    public static func expansion<D: DeclGroupSyntax, C: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingMembersOf declaration: D,
        in context: C
    ) throws -> [DeclSyntax] {
        let typeName = declaration.typeName
        let isDeclEnum = declaration.is(EnumDeclSyntax.self)
        let inheritsFromRawRepresentable = declaration.inherits(from: rawRepresentableNames)

        switch (inheritsFromRawRepresentable, isDeclEnum) {
        case (false, true) where declaration.inheritedTypes().isEmpty: 
            throw DiagnosticsError(
                diagnostics: [
                    Diagnostic.enumMissingRawValueType.diagnose(at: declaration)
                ]
            )

        case (false, false):
            throw DiagnosticsError(
                diagnostics: [
                    Diagnostic.notRawRepresentable.diagnose(at: declaration)
                ]
            )

        default:
            break
        }

        let access = declaration.modifiers.first(where: \.isNeededAccessLevelModifier)

        let decodeDecl: DeclSyntax = if declaration.containsFailableInitRawValue() {
            """
            \(access)init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let value = try \(typeName)(rawValue: container.decode(RawValue.self))

                guard let value else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Unable to decode value of type `RawValue` from data."
                    )
                }

                self = value
            }
            """

        } else {
            """
            \(access)init(from decoder: Decoder) throws {
                try self.init(rawValue: decoder.singleValueContainer().decode(RawValue.self))
            }
            """
        }

        return [decodeDecl]
    }

    public static func expansion<D: DeclGroupSyntax, T: TypeSyntaxProtocol, C: MacroExpansionContext>(
        of node: AttributeSyntax,
        attachedTo declaration: D,
        providingExtensionsOf type: T,
        conformingTo protocols: [TypeSyntax],
        in context: C
    ) throws -> [ExtensionDeclSyntax] {
        if declaration.inherits(from: conformanceNames) {
            return []
        }

        let ext: DeclSyntax = """
            extension \(type.trimmed): \(raw: Self.qualifiedConformanceName) {}
            """

        return [ext.cast(ExtensionDeclSyntax.self)]
    }
}
