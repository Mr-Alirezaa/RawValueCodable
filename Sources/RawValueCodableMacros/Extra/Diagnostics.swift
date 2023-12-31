import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

enum MacroDiagnostic<M: RawValueCodingMacro> {
    case notRawRepresentable
    case enumMissingRawValueType
}

extension MacroDiagnostic: DiagnosticMessage {
    var macroName: String { M.macroName }

    var severity: DiagnosticSeverity { return .error }

    var message: String {
        switch self {
        case .notRawRepresentable:
            "@\(macroName) can only be applied to a type conforming to '\(RawValueCodableMacro.rawRepresentable)'"
        case .enumMissingRawValueType:
            "@\(macroName) can only be applied to an enum conforming to '\(RawValueCodableMacro.rawRepresentable)' explicitly or an enum with raw value"
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .notRawRepresentable:
            MessageID(domain: "RawValueCodableMacros", id: "notRawRepresentable")
        case .enumMissingRawValueType:
            MessageID(domain: "RawValueCodableMacros", id: "enumMissingRawValueType")
        }
    }

    func diagnose<S: SyntaxProtocol>(at node: S) -> Diagnostic {
        Diagnostic(node: node, message: self)
    }
}

enum MacroFixIt: String, FixItMessage {
    case addRawRepresentableConformance

    var message: String {
        switch self {
        case .addRawRepresentableConformance:
            "Add 'RawRepresentable' conformance"
        }
    }

    var fixItID: MessageID {
        MessageID(domain: "RawValueCodableMacros", id: rawValue)
    }
}
