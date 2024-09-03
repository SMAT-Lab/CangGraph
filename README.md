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

使用messages进行请求
```cangjie
from std import collection.*
from std import os.*
from std import os.posix.*
import titoken.*
from net import http.*
from net import tls.*
from serialization import serialization.*
from encoding import json.*
import requests.*
import llmapi.*
import util.*
import tool.*

main(): Int64 {

    let model: GPTGod = ((getLLMInstance(LLMType.GPTGod)) as GPTGod).getOrThrow()
    let msgs = ArrayList<Message>()
    msgs.append(Message("system", "You are a helpful assistant"))
    // msgs.append(Message("user", "What is the weather like today in New York?"))
    msgs.append(Message("user", "Who you are?"))
    let base_tools = ArrayList<BaseTool>([GetWeather()])
    let tools = ArrayList<Tool>()
    for (tool in base_tools) {
        tools.append(tool.tool)
    }

    let res = model.query(msgs.toArray(), stop: false, tools: tools.toArray() , useTool: false)
    println(res)

    return 0 
}
```

### ReAct
```cangjie
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
    let agent = ReActAgent(ArrayList<BaseTool>([GetWeather(), FileSaver()]))
    println(agent.invoke("What is the weather like in New York?").serialize().toJson())
}
```

## Node
在canggraph中，每个node都是一个可执行对象，可以是Agent，可以是Chain，可以是Tool
因此，每个node中都有一个runnable属性，该属性存储的是Runnable对象，agent，chain，tool都是Runnable的子类
在执行一个node的时候，只需要执行node.runnable.run()即可

### Tool
```cj
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

    let tool = GoogleSearchRun()
    let input = Dict()
    input.put("query","Dijkstra algorithm")

    let res: ResponseMessage = tool.invoke(input)
    println(res.serialize().toJson())
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
    let llm = (getLLMInstance(LLMType.OPEN_AI) as OpenAI).getOrThrow()
    let tools = ArrayList<BaseTool>([GetWeather(), GoogleSearchRun()])

    let agent = create_openai_tools_agent(llm, tools)
    let input = Dict()
    input["input"] = "what is the weather like the day after tomorrow in Guangzhou?"
    let res = agent.invoke(input)
    println(res.serialize().toJson())
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
    input["text"] = "What is the weather like today in Guangzhou?"
    let res = chain.invoke(input)
    println(res.serialize().toJson())
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
    let llm = (getLLMInstance(LLMType.OPEN_AI, model: "gpt-4o-mini") as OpenAI).getOrThrow()
    let parameters = HashMap<String, Parameter>()
    let next: Parameter = Parameter("Next", "The next role to act", true)
    parameters["next"] = next
    let function_def = BaseFunction("RouteDecider", "Select the next role to act", parameters)

    let tools = ArrayList<BaseTool>([GetWeather()])

    let chain = CoTChain(llm, promptTemplate:SelfDefinePromptTemplate(), tools:tools)
    chain.bind_function(function_def)
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
    // let input = Dict()
    // input["text"] = "who should act next?"
    // let res = supervisor_node.run(input)
    // println(res)

    // tool
    let tool = GoogleSearchRun()
    // let input2 = Dict()
    // input2.put("query","Dijkstra algorithm")
    let researcher_node = Node("GoogleSearch", "tool", tool)
    // let res2 = tool_node.run(input2)
    // println(res2)

    // agent

    let agent = create_openai_tools_agent(llm, ArrayList<BaseTool>([GetWeather()]))
    let weather_agent = Node("Weather", "agent", agent)

    let agent3 = create_openai_tools_agent(llm, ArrayList<BaseTool>())
    let coder_agent = Node("Coder", "agent", agent3)

    
    // let res3 = weather_agent.run(input3)
    // println(res3)

    // graph
    let graph = Graph()
    graph.addNode(supervisor_node)
    graph.addNode(weather_agent)
    graph.addNode(researcher_node)
    graph.addNode(coder_agent)

    graph.setEntryPoint(supervisor_node)

    graph.addConditionalEdge(supervisor_node, researcher_node)
    graph.addConditionalEdge(supervisor_node, coder_agent)
    graph.addConditionalEdge(supervisor_node, weather_agent)

    graph.addEdge(researcher_node, supervisor_node)
    graph.addEdge(coder_agent, supervisor_node)
    graph.addEdge(weather_agent, supervisor_node)

    graph.setExitPoint(supervisor_node)

    let input3 = Dict()
    input3.put("text", "what is the weather like today in Guangzhou?")
    graph.invoke(input3)
}
```

## tokenizer
```cangjie
from std import collection.*
from std import os.*
from std import os.posix.*
import titoken.*

main(): Int64 {
    var sentences:Array<String> =  ["苍穹是什么","苍穹"]
    //分词
    let tokenizer = Tokenizer(tokensFilePath: getcwd()+"/resource/tokenizer.json")
    let embedder = Embedder(modelPath: getcwd()+"/resource/embedding_model.onnx", tokensFilePath:getcwd()+"/resource/tokenizer.json")
    println("tokens: ${tokenizer(sentences)}")
    //计算词嵌入向量
    let sentence_embeddings = embedder(sentences)
    println("embedding: ${sentence_embeddings}")
    return 0 
}
```

## RAG + arkts代码修复
```cangjie
from std import collection.*
from std import os.*
from std import os.posix.*
import titoken.*
from net import http.*
from net import tls.*
from serialization import serialization.*
from encoding import json.*
import requests.*
import llmapi.*
import util.*

main(): Int64 {

    let pineCone = PineCone()
    // 往向量数据库中添加数据
    let path: String = getcwd()
    // let obj = read_from_csv("${path}/data/demo.csv", header: true)
    // let vectors: ArrayList<Vector> = pineCone.get_vectors(obj)
    // pineCone.upsertVectors(vectors)
    // 查询向量数据库
    let objs = read_from_csv("${path}/data/test.csv", header: true)
    let row = objs[4].asObject().get("values").getOrThrow().asArray()
    let query_rule: String = row[0].asString().getValue()
    println(query_rule)
    let query_description = row[1].asString().getValue()
    let query_buggy_code = row[2].asString().getValue()
    println(query_buggy_code)
    let res: JsonObject = pineCone.query(query_buggy_code, rule: query_rule, top_k:3)
    let similars = res["matches"].asArray()
    var prompt = "我将给出你若干个与问题代码类型相同，问题代码类似的例子，包括缺陷规则、缺陷描述、缺陷代码、缺陷解释以及修复代码\n"
    for (index in 0..similars.size()) {
        let item = similars[index].asObject()["metadata"].asObject()
        let rule = item["rule"].asString().getValue()
        let description = item["description"].asString().getValue()
        let buggy_code = item["buggy_code"].asString().getValue()
        let buggy_explanation = item["buggy_explanation"].asString().getValue()
        let fixed_code = item["fixed_code"].asString().getValue()

        prompt = prompt + "Demo: ${index}\nRule: ${rule}\nDescription: ${description}\nBuggy Code: \n${buggy_code}\nBuggy Explanation: ${buggy_explanation}\nFixed Code:\n${fixed_code}\n"
    }
    prompt = prompt + "现在，请根据上面的例子，来修复我的问题代码:\n${query_buggy_code}\n\n对应的问题类型是: ${query_rule}\n该问题类型的描述如下:${query_description}\n请您帮我修复一下: \n```arkts\n"
    //prompt =  "请修复我的问题代码:\n```arkts\n${query_buggy_code}\n```\n\n请您帮我修复一下: \n```arkts\n"
    println(prompt)
    let llm: Ollama = (getLLMInstance(LLMType.OLLAMA, model: "arktsLLM") as Ollama).getOrThrow()
    let msgs: ArrayList<Message> = ArrayList<Message>()
    let sys_msg = Message("system", "You are a helpful assistant!")
    let msg = Message("user", prompt)
    msgs.append(sys_msg)
    msgs.append(msg)

    let response = llm.query(msgs)
    println(response)

    return 0 
}
```