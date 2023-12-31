import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct RawValueEncodableMacro: RawValueCodingMacro {
    static let macroName = "RawValueCodable"

    static let conformanceName = "Encodable"
    static var qualifiedConformanceName: String { "Swift.\(Self.conformanceName)" }
    static var conformanceNames: [String] { [Self.conformanceName, Self.qualifiedConformanceName] }

    static let rawRepresentable = "RawRepresentable"
    static var qualifiedRawRepresentable = "Swift.\(rawRepresentable)"
    static var rawRepresentableNames = [Self.rawRepresentable, Self.qualifiedRawRepresentable]
}

extension RawValueEncodableMacro: MemberMacro, ExtensionMacro {
    typealias Diagnostic = MacroDiagnostic<Self>

    public static func expansion<D: DeclGroupSyntax, C: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingMembersOf declaration: D,
        in context: C
    ) throws -> [DeclSyntax] {
        let inheritedTypeNames = declaration.inheritanceClause?
            .inheritedTypes
            .map { $0.type.trimmedDescription } ?? []

        let isDeclEnum = declaration.is(EnumDeclSyntax.self)
        let inheritsFromRawRepresentable = inheritedTypeNames.contains(where: { rawRepresentableNames.contains($0) })

        switch (inheritsFromRawRepresentable, isDeclEnum) {
        case (false, true) where inheritedTypeNames.isEmpty:
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

        let encodeDecl: DeclSyntax = """
            \(access)func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(self.rawValue)
            }
            """

        return [encodeDecl]
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
