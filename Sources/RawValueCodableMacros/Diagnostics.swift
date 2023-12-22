import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

enum MacroDiagnostic: String, DiagnosticMessage {
    case notRawRepresentable

    var severity: DiagnosticSeverity { return .error }

    var message: String {
        switch self {
        case .notRawRepresentable:
            "This attribute can only be applied to a type conforming to 'RawRepresentable'"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "RawValueCodableMacros", id: rawValue)
    }
}

enum Fixits: String, FixItMessage {
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
