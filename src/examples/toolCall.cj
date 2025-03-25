package canggraph.examples

import canggraph.llmapi.*
import canggraph.tool.*
import canggraph.util.*

import std.collection.*
import encoding.json.*

public func toolCall() {
    let toolArgs = ToolArgs(
        "translater",
        "Translate Chinese to another language.",
        ToolParameters(
            "object",
            HashMap<String, ToolProperties>([
                ("text", ToolProperties("string", "text to translate")),
                ("target_language", ToolProperties("string", "language translated into"))
            ]),
            ["text", "target_language"],
            false
        )
    )

    let translater: Tool = Tool(
        "function",
        toolArgs
    )

    let llm = getLLMInstance(LLMType.DeepSeek, model: "deepseek-chat")

    let res = llm.query("Translate `你好，世界。` into English", [translater]).getToolCalls()
    println("tool_call:")
    println("${res}")
    
    return 0
}
