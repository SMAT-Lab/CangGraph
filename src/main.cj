import llmapi.*
import graph.*
import tool.*
import agent.*
import schema.*
import chain.*
from std import collection.*
from encoding import json.*
from std import ffi.python.*

main() {
    // chain
    let llm = (getLLMInstance(LLMType.OPEN_AI, model: "gpt-4o-mini") as OpenAI).getOrThrow()
    let parameters = HashMap<String, Parameter>()
    let next: Parameter = Parameter("Next", "The next role to act", true)
    parameters["next"] = next
    let function_def = BaseFunction("RouteDecider", "Select the next role to act", parameters)
    let func_schema: JsonValue = get_function_schema(function_def)

    let tools = ArrayList<BaseTool>([GetWeather()])

    let chain = CoTChain(llm, promptTemplate:SelfDefinePromptTemplate(), tools:tools)
    chain.bind_function(func_schema)
    let members = ArrayList<String>(["Researcher", "Coder", "Weather"])
    var options = members.clone()
    options.append("FINISH")
    chain.add_prompt("system_message", 
      """
      You are a supervisor tasked with managing a conversation between the
      following workers: ${members}. Given the following user request,
      respond with the worker to act next. Each worker will perform a
      task and respond with their results and status. When finished,
      respond with FINISH.
      Given the conversation above, who should act next?
      Or should we FINISH? Select one of: ${options}
      !!!You must call the tool 'RouteDecider' to help you make the decision. 
      """
    )

    let supervisor_node = Node("supervisor", "chain", chain)
    let input = Dict()
    input["input"] = "who should act next?"
    // let res = supervisor_node.run(input)
    // println(res)

    // tool
    let tool = pythonREPL()
    let input2 = Dict()
    input2.put("code", """
def main():
    print('hello world')
""")
    input2.put("filename","test")
    let tool_node = Node("pythonREPL", "tool", tool)
    // let res2 = tool_node.run(input2)
    // println(res2)

    // agent

    let agent = create_openai_tools_agent(llm, ArrayList<BaseTool>([GetWeather()]))

    let weather_agent = Node("Weather", "agent", agent)
    let input3 = Dict()
    input3.put("input", "what is the weather like today in Guangzhou?")
    // let res3 = weather_agent.run(input3)
    // println(res3)

    // graph
    let graph = Graph()
    graph.addNode(supervisor_node)
    graph.addNode(tool_node)
    graph.addNode(weather_agent)

    graph.setEntryPoint(supervisor_node)

    // graph.addEdge(supervisor_node, tool_node)
    graph.addEdge(tool_node, weather_agent)
    graph.addEdge(supervisor_node, weather_agent)
    graph.addEdge(weather_agent, supervisor_node)

    graph.setExitPoint(supervisor_node)

    graph.invoke(input3)
}