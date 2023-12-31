import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct RawValueCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        RawValueDecodableMacro.self,
        RawValueEncodableMacro.self,
        RawValueCodableMacro.self,
    ]
}
