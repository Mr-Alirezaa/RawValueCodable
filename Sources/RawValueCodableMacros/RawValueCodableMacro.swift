import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

protocol RawValueCodingMacro: MemberMacro, ExtensionMacro {
    static var macroName: String { get }
}

public struct RawValueCodableMacro: RawValueCodingMacro {
    static let macroName = "RawValueCodable"

    static let conformanceName = "Codable"
    static var qualifiedConformanceName: String { "Swift.\(Self.conformanceName)" }
    static var conformanceNames: [String] { [Self.conformanceName, Self.qualifiedConformanceName] }

    static let rawRepresentable = "RawRepresentable"
    static var qualifiedRawRepresentable = "Swift.\(rawRepresentable)"
    static var rawRepresentableNames = [Self.rawRepresentable, Self.qualifiedRawRepresentable]
}

extension RawValueCodableMacro: MemberMacro, ExtensionMacro {
    typealias Diagnostic = MacroDiagnostic<Self>

    public static func expansion<D: DeclGroupSyntax, C: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingMembersOf declaration: D,
        in context: C
    ) throws -> [DeclSyntax] {
        do {
            let decodableMacroExpansion = try RawValueDecodableMacro.expansion(of: node, providingMembersOf: declaration, in: context)
            let encodableMacroExpansion = try RawValueEncodableMacro.expansion(of: node, providingMembersOf: declaration, in: context)

            return [decodableMacroExpansion, encodableMacroExpansion].flatMap { $0 }
        } catch {
            throw error.replacingDiagnosticType()
        }
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

extension Error {
    fileprivate func replacingDiagnosticType() -> Error {
        guard case var error as DiagnosticsError = self else { return self }

        let diagnostics = error.diagnostics.map { diag in
            switch diag.diagMessage {
            case RawValueDecodableMacro.Diagnostic.notRawRepresentable,
                RawValueEncodableMacro.Diagnostic.notRawRepresentable:
                SwiftDiagnostics.Diagnostic(
                    node: diag.node,
                    position: diag.position,
                    message: RawValueCodableMacro.Diagnostic.notRawRepresentable,
                    highlights: diag.highlights,
                    notes: diag.notes,
                    fixIts: diag.fixIts
                )

            case RawValueDecodableMacro.Diagnostic.enumMissingRawValueType,
                RawValueEncodableMacro.Diagnostic.enumMissingRawValueType:
                SwiftDiagnostics.Diagnostic(
                    node: diag.node,
                    position: diag.position,
                    message: RawValueCodableMacro.Diagnostic.enumMissingRawValueType,
                    highlights: diag.highlights,
                    notes: diag.notes,
                    fixIts: diag.fixIts
                )
            default:
                diag
            }
        }

        error.diagnostics = diagnostics
        return error
    }
}
