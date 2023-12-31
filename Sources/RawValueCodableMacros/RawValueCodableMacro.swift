import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

protocol RawValueCodingMacro: MemberMacro, ExtensionMacro {
    static var macroName: String { get }
}

public struct RawValueCodableMacro: MemberMacro, ExtensionMacro, RawValueCodingMacro {
    typealias Diagnostic = MacroDiagnostic<Self>

    static let macroName = "RawValueCodable"
    static let conformanceName = "Codable"
    static var qualifiedConformanceName: String { "Swift.\(Self.conformanceName)" }
    static var conformanceNames: [String] { [Self.conformanceName, Self.qualifiedConformanceName] }

    static let rawRepresentable = "RawRepresentable"
    static var qualifiedRawRepresentable = "Swift.\(rawRepresentable)"
    static var rawRepresentableNames = [Self.rawRepresentable, Self.qualifiedRawRepresentable]

    public static func expansion<D: DeclGroupSyntax, C: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingMembersOf declaration: D,
        in context: C
    ) throws -> [DeclSyntax] {
        do {
            return try RawValueDecodableMacro.expansion(of: node, providingMembersOf: declaration, in: context)
            + RawValueEncodableMacro.expansion(of: node, providingMembersOf: declaration, in: context)
        } catch var error as DiagnosticsError {
            let diagnostics = error.diagnostics.map { diag in
                switch diag.diagMessage {
                case MacroDiagnostic<RawValueDecodableMacro>.notRawRepresentable,
                    MacroDiagnostic<RawValueEncodableMacro>.notRawRepresentable:
                    return SwiftDiagnostics.Diagnostic(
                        node: diag.node,
                        position: diag.position,
                        message: Diagnostic.notRawRepresentable,
                        highlights: diag.highlights,
                        notes: diag.notes,
                        fixIts: diag.fixIts
                    )
                default:
                    return diag
                }
            }

            error.diagnostics = diagnostics
            throw error

        } catch {
            throw error
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
