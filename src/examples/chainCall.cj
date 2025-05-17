package canggraph.examples

import canggraph.chain.*
import canggraph.llmapi.*
import canggraph.schema.*
import canggraph.tool.*
import canggraph.util.*

import std.collection.*
import encoding.json.*

public func chainCall() {
    // let llm = getLLMInstance(LLMType.DeepSeek, model: "deepseek-chat")
    // let parameters = HashMap<String, Parameter>()
    // let next: Parameter = Parameter("next", "String", true)
    // parameters["next"] = next
    // let function_def = BaseFunction("route", "Select the next role", parameters)

    // let tools = ArrayList<BaseTool>([GetWeather()])

    // let chain = CoTChain(llm, promptTemplate:SelfDefinePromptTemplate(), tools:tools)
    // chain.bind_function(function_def)
    // let members = ArrayList<String>(["Researcher", "Coder"])
    // let options = members.append("FINISH")
    // chain.add_prompt("system_message", 
    //   """
    //   You are a supervisor tasked with managing a conversation between the
    //   following workers: ${members}. Given the following user request,
    //   respond with the worker to act next. Each worker will perform a
    //   task and respond with their results and status. When finished,
    //   respond with FINISH.
    //   Given the conversation above, who should act next?
    //   Or should we FINISH? Select one of: ${options}
    //   Please call the tool to help you make the decision.
    //   """
    // )
    // let input = HashMap<String, String>()
    // input["text"] = "What is the weather like today in Guangzhou?"
    // let res = chain.invoke(input)
    // println(res.serialize().toJson())
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