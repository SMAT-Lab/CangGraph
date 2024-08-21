import llmapi.*
import graph.*
import tool.*
import agent.*
import schema.*
import chain.*
from std import collection.*
from encoding import json.*
import util.*

main() {
    let llm = getLLMInstance(LLMType.OPEN_AI)
    let parameters = HashMap<String, Parameter>()
    let next: Parameter = Parameter("next", "String", true)
    parameters["next"] = next
    let function_def = BaseFunction("route", "Select the next role", parameters)

    let tools = ArrayList<BaseTool>([GetWeather()])

    let chain = CoTChain(llm, promptTemplate:SelfDefinePromptTemplate(), tools:tools)
    chain.bind_function(function_def)
    let members = ArrayList<String>(["Researcher", "Coder"])
    let options = members.append("FINISH")
    chain.add_prompt("system_message", 
      """
      You are a supervisor tasked with managing a conversation between the
      following workers: ${members}. Given the following user request,
      respond with the worker to act next. Each worker will perform a
      task and respond with their results and status. When finished,
      respond with FINISH.
      Given the conversation above, who should act next?
      Or should we FINISH? Select one of: ${options}
      Please call the tool to help you make the decision.
      """
    )
    let input = Dict()
    input["input"] = "What is the weather like today in Guangzhou?"
    let res = chain.invoke(input)
    println(res.serialize().toJson())
}