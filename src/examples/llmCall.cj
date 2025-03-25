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
