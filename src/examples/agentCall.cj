package canggraph.examples

import canggraph.agent.*
import canggraph.llmapi.*
import canggraph.tool.*
import canggraph.util.*

import std.collection.*
import encoding.json.*

public func agentCall() {
    let llm = getLLMInstance(LLMType.DeepSeek, model: "deepseek-chat")

    let prompt = """
                You're a calculater.
                Calculate the x in the formula with detailed process.
                """
    let messages = ArrayList<Message>()
    messages.append(Message("system", prompt))
    messages.append(Message("user", "Here is the formula: `3x + 2 = 0`"))

    println(llm.query(messages.toArray()).getContent())
}

public func agentCallWithTool() {
    let toolArgs = ToolArgs(
        "get_order_status",
        "Get the status of an order with the order id.",
        ToolParameters(
            "object",
            HashMap<String, ToolProperties>([
                ("order_id", ToolProperties("string", "order id")),
                ("user_id", ToolProperties("string", "user id(optional)"))
            ]),
            ["order_id"],
            false
        )
    )

    let translater: Tool = Tool(
        "function",
        toolArgs
    )

    let llm = getLLMInstance(LLMType.DeepSeek, model: "deepseek-chat")

    let prompt = getPromptFromFile("./src/examples/input.txt")
    
    let messages = ArrayList<Message>()
    messages.append(Message("system", prompt))
    messages.append(Message("user", "Where is my order `ORD123456`?"))

    println("tool call:")
    println(llm.query(messages.toArray(), [translater]).getToolCalls())
}