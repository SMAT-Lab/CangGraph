package canggraph.examples

import canggraph.llmapi.*
import canggraph.util.*

import std.collection.*
import encoding.json.*

public func llmCall() {
    let llm = getLLMInstance(LLMType.DeepSeek, model: "deepseek-chat")

    println(llm.query("who are you?").getContent())
    return 0
}

public func llmCallWithMessage() {
    let llm = getLLMInstance(LLMType.DeepSeek, model: "deepseek-chat")

    let messages = ArrayList<Message>()
    messages.append(Message("system", "You're a calculater. Calculate the x in the formula with detailed process."))
    messages.append(Message("user", "Here is the formula: x * 2 - 3x + 2 = 0"))
    println(llm.query(messages.toArray()).getContent())
}