import llmapi.*
import graph.*

main() {
  // let llm = getLLMInstance(LLMType.OPEN_AI)
  // println(llm.query("who are you?"))
  // println(llm.query("translate what you have said into Chinese"))
  var graph: Graph = Graph()
  graph.addNode("testNode", "")
  graph.addNode("testEmpty", "")

  graph.setEntryPoint("testNode")

  graph.addEdge("testNode", "testEmpty")
  graph.addEdge("testEmpty", "__end__")
  graph.avoke("who are you?")
}
