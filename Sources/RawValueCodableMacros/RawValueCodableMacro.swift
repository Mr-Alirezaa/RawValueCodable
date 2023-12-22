import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct RawValueDecodableMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let inheritedTypeNames = declaration.inheritanceClause?
            .inheritedTypes
            .map { $0.cast(InheritedTypeSyntax.self) }
            .compactMap({ $0.type.as(IdentifierTypeSyntax.self)?.name.text })

        if let inheritedTypeNames, !inheritedTypeNames.contains("RawRepresentable") {
//            if var inheritedTypes = declaration.inheritanceClause?.inheritedTypes {
//                inheritedTypes.append(InheritedTypeSyntax(type: TypeSyntax.rawRepresentableProtocol))
//
//                let newNode = declaration.inheritanceClause?.with(\.inheritedTypes, inheritedTypes)
//            }
//
//            let fixit = FixIt(
//                message: Fixits.addRawRepresentableConformance,
//                changes: [.replace(oldNode: Syntax(declaration), newNode: Syntax(declaration))]
//            )
            let diagnostic = Diagnostic(node: node, message: MacroDiagnostic.notRawRepresentable)
        }

        let initSytnax = DeclSyntax(
            """
            init(from decoder: Decoder) throws {
                try self.init(rawValue: decoder.singleValueContainer().decode(RawValue.self))
            }
            """
        )
//        .with(\.modifiers, declaration.modifiers)

        print(initSytnax.debugDescription)

        return [initSytnax]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let inheritedTypeSyntaxItems = [InheritedTypeSyntax(type: TypeSyntax("Decodable"))]
        let extensionDecl = ExtensionDeclSyntax(
            modifiers: declaration.modifiers,
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax(inheritedTypes: InheritedTypeListSyntax(inheritedTypeSyntaxItems)),
            memberBlock: MemberBlockSyntax(members: "")
        )

        return [extensionDecl]
    }
}

public struct RawValueEncodableMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let decoderInit = DeclSyntax(
            """
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(self.rawValue)
            }
            """
        )

        return [decoderInit]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let inheritedTypeSyntaxItems = [InheritedTypeSyntax(type: TypeSyntax("Encodable"))]
        let extensionDecl = ExtensionDeclSyntax(
            modifiers: declaration.modifiers,
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax(inheritedTypes: InheritedTypeListSyntax(inheritedTypeSyntaxItems)),
            memberBlock: MemberBlockSyntax(members: "")
        )

        return [extensionDecl]
    }
}

public struct RawValueCodableMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try RawValueDecodableMacro.expansion(of: node, providingMembersOf: declaration, in: context)
        + RawValueEncodableMacro.expansion(of: node, providingMembersOf: declaration, in: context)
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let inheritedTypeSyntaxItems = [InheritedTypeSyntax(type: TypeSyntax("Codable"))]
        let extensionDecl = ExtensionDeclSyntax(
            modifiers: declaration.modifiers,
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax(inheritedTypes: InheritedTypeListSyntax(inheritedTypeSyntaxItems)),
            memberBlock: MemberBlockSyntax(members: "")
        )

        return [extensionDecl]
    }
}

@main
struct RawValueCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        RawValueDecodableMacro.self,
        RawValueEncodableMacro.self,
        RawValueCodableMacro.self,
    ]
}
