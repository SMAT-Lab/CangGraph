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

    // println(llm.query("Translate `你好，世界。` into English", [translater]).getContent())
    
    return 0
}

public func toolCallWithMessage() {
    let toolArgs = ToolArgs(
        "translater",
        "Translate Chinese to English.",
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
    
    let messages = ArrayList<Message>()
    messages.append(Message("system", "You're a professor with various of tools. Choose proper tool to answer questions."))
    messages.append(Message("user", "Translate `你好，世界。` into English"))

    println("tool call:")
    println(llm.query(messages.toArray(), [translater]).getToolCalls())
    return 0
}