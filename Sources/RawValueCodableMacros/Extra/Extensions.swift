import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

extension SyntaxStringInterpolation {
    mutating func appendInterpolation<Node: SyntaxProtocol>(_ node: Node?) {
        if let node {
            self.appendInterpolation(node)
        }
    }

    mutating func appendInterpolation() {
        self.appendInterpolation(TokenSyntax.identifier("Goz"))
    }
}

extension DeclGroupSyntax {
    var typeName: TokenSyntax {
        self.as(EnumDeclSyntax.self)?.name.trimmed
        ?? self.as(StructDeclSyntax.self)?.name.trimmed
        ?? self.as(ClassDeclSyntax.self)?.name.trimmed
        ?? .keyword(.Self)
    }

    func inheritedTypes() -> [TypeSyntax] {
        inheritanceClause?
            .inheritedTypes
            .map { $0.type } ?? []
    }

    func inherits(from types: some Collection<String>) -> Bool {
        inheritedTypes()
            .map(\.trimmedDescription)
            .contains { types.contains($0) }
    }

    func initRawValue() -> InitializerDeclSyntax? {
        guard
            let initDecl = memberBlock.members
                .first(where: { $0.decl.is(InitializerDeclSyntax.self) })?.decl
                .cast(InitializerDeclSyntax.self)
        else { return nil }

        let parameters = initDecl.signature.parameterClause.parameters

        guard
            parameters.count == 1,
            parameters.first!.firstName.trimmedDescription == "rawValue"
        else { return nil }

        return initDecl
    }

    func containsFailableInitRawValue() -> Bool {
        var isInitFailable = true
        if let initDecl = initRawValue() {
            isInitFailable = initDecl.optionalMark != nil
        }

        return isInitFailable
    }
}

extension DeclModifierSyntax {
    var isNeededAccessLevelModifier: Bool {
        switch self.name.tokenKind {
        case .keyword(.public): return true
        case .keyword(.package): return true
        default: return false
        }
    }
}
