package canggraph.examples

import canggraph.chain.*
import canggraph.llmapi.*
import canggraph.schema.*
import canggraph.tool.*
import canggraph.util.*

import std.collection.*
import encoding.json.*

public func chainCall() {
    let llm1 = getLLMInstance(LLMType.DeepSeek, model: "deepseek-chat")
    let template1 = LLMPromptTemplate(
        ["name", "color"],
        "你是一个植物学家。给定花的名称和颜色，你需要为这种花写一个200字左右的介绍。\n花名: {name}\n颜色: {color}\n植物学家: 这是关于上述花的介绍:"
    )
    let set1 = HashSet<String>(["introduction"])
    let chain1 = SimpleChain(llm1, template1, set1)
    // chain.invoke(Dict([("name", "玫瑰"), ("color", "黑色")]))

    let llm2 = getLLMInstance(LLMType.DeepSeek, model: "deepseek-chat")
    let template2 = LLMPromptTemplate(
        ["introduction"],
        "你是一位鲜花评论家。给定一种花的介绍，你需要为这种花写一篇200字左右的评论。\n鲜花介绍:\n{introduction}\n花评人对上述花的评论:"
    )
    let set2 = HashSet<String>(["review"])
    let chain2 = SimpleChain(llm2, template2, set2)

    let allChain = SequentialChain(
        Array<SimpleChain>([chain1, chain2]),
        HashSet<String>(["name", "color"]),
        HashSet<String>(["introduction", "review"])
    )

    allChain.invokeChain(Dict([("name", "玫瑰"), ("color", "黑色")]))
    
}