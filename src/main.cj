import llmapi.*
import graph.*
import tool.*
import agent.*
from std import collection.*

main() {
  // let llm = getLLMInstance(LLMType.OPEN_AI)
  // println(llm.query("who are you?"))
  // println(llm.query("translate what you have said into Chinese"))
  let llm = getLLMInstance(LLMType.OPEN_AI)
  let tools = ArrayList<BaseTool>([GetWeather()])

  let res = create_openai_tools_agent(llm, tools, "what is the weather like today in GuangzhouS?")
  print(res)
  // var graph: Graph = Graph()
  // graph.addNode("testNode", "")
  // graph.addNode("testEmpty", "")

  // graph.setEntryPoint("testNode")

  // graph.addEdge("testNode", "testEmpty")
  // graph.addEdge("testEmpty", "__end__")
  // graph.avoke("who are you?")
}
