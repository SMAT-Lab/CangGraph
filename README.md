### 基础用法——大模型的交互
```cj
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

  println(llm.query("who are you?"))
  println(llm.query("translate what you have said into Chinese"))
}
```

## Node
在canggraph中，每个node都是一个可执行对象，可以是Agent，可以是Chain，可以是Tool
因此，每个node中都有一个runnable属性，该属性存储的是Runnable对象，agent，chain，tool都是Runnable的子类
在执行一个node的时候，只需要执行node.runnable.run()即可

### pythonREPL
```cj
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


    let tool = pythonREPL()
    let args = Dict()
    args.put("code", """
def main():
    print('hello world')
""")
    args.put("filename","test")

    println(tool.invoke(args))
}
```

### 工具执行agent
```cj
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
    let tools = ArrayList<BaseTool>([GetWeather(), pythonREPL()])

    let agent = create_openai_tools_agent(llm, tools)
    let input = Dict()
    input["input"] = "what is the weather like today in Guangzhou?"
    let res = agent.invoke(input)
    print(res)
}
```

### 自定义chain
```cj
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
    let parameters = HashMap<String, Parameter>()
    let next: Parameter = Parameter("next", "String", true)
    parameters["next"] = next
    let function_def = BaseFunction("route", "Select the next role", parameters)
    let func_schema: JsonValue = get_function_schema(function_def)

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
    let input = Dict()
    input["input"] = "What is the weather like today in Guangzhou?"
    let res = chain.invoke(input)
    println(res)
}
```

## Graph
```cangjie
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
    let llm = getLLMInstance(LLMType.OPEN_AI, model: "gpt-4o-mini")
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
```