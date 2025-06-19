package canggraph.examples

import canggraph.llmapi.*
import canggraph.tool.*
import canggraph.util.*

import std.collection.*
import encoding.json.*

public func toolCall() {
    let toolArgs = ToolArgs(
        "撰写花卉评价",
        "撰写花卉的评价，用户需要先输入花卉信息",
        ToolParameters(
            "object",
            HashMap<String, ToolProperties>([
                ("name", ToolProperties("string", "name of the flower")),
                ("color", ToolProperties("string", "color of the flower"))
            ]),
            ["name", "color"],
            false
        )
    )

    let flower_review: Tool = Tool(
        "function",
        toolArgs
    )

    let llm = getLLMInstance(LLMType.DeepSeek, model: "deepseek-chat")

    let res = llm.query("为黑色玫瑰撰写一个评价", [flower_review]).getToolCalls()
    println("tool_call:")
    println("${res}")
    
    return 0
}
