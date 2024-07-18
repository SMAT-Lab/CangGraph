import llmapi.*
import graph.*
import tool.*
import agent.*
import schema.*
import chain.*
from std import collection.*
from encoding import json.*

main() {
  let llm = getLLMInstance(LLMType.OPEN_AI)
  // println(llm.query("who are you?"))
  // println(llm.query("translate what you have said into Chinese"))
  let parameters = HashMap<String, Parameter>()
  let next: Parameter = Parameter("next", "String", true)
  parameters["next"] = next
  let function_def = BaseFunction("route", "Select the next role", parameters)
  let func_schema: JsonValue = get_function_schema(function_def)
  // print(func_schema)

  // let llm = getLLMInstance(LLMType.OPEN_AI)
  let tools = ArrayList<BaseTool>([GetWeather()])

  let chain = CoTChain(llm, promptTemplate:SelfDefinePromptTemplate(), tools:tools)
  chain.bind_function(func_schema)
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
  let res = chain.avoke("Code hello world and print it to the terminal")
  println(res)

  // let agent = create_openai_tools_agent(llm, tools)
  // let res2 = agent.run("what is the weather like today in Guangzhou?")
  // print(res2)
  // var graph: Graph = Graph()
  // graph.addNode("testNode", "")
  // graph.addNode("testEmpty", "")

  // graph.setEntryPoint("testNode")

  // graph.addEdge("testNode", "testEmpty")
  // graph.addEdge("testEmpty", "__end__")
  // graph.avoke("who are you?")
}
