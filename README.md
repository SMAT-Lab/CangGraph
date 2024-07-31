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