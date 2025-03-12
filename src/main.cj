package canggraph

import canggraph.multi.*

/*
import canggraph.graph.*
import canggraph.tool.*
import canggraph.agent.*
import canggraph.schema.*
import canggraph.chain.*
import canggraph.util.*
import temp.*
*/
import std.{fs.*, collection.*, time.*, sync.*}
import encoding.json.*
import net.http.*

func startServer(): Unit {
    // 1. 构建 Server 实例
    let server = ServerBuilder()
                        .addr("127.0.0.1")
                        .port(8081)
                        .build()
    var a: HttpRequestHandler = FuncHandler({ httpContext =>
        httpContext.responseBuilder.body("index")
    })
    var b: HttpRequestHandler = FuncHandler({ httpContext =>
        httpContext.responseBuilder.body("id")
    })
    var c: HttpRequestHandler = FuncHandler({ httpContext =>
        httpContext.responseBuilder.body("help")
    })
    server.distributor.register("/index", a)
    server.distributor.register("/id", b)
    server.distributor.register("/help", c)
    server.distributor.register("/graph", FuncHandler({ httpContext =>
        let request = httpContext.request
        if (request.method != "POST") {
            httpContext.responseBuilder.body("Method not allowed")
            return
        }
        let body = request.body
        
        let buf = Array<UInt8>(10000000, item: 0)
        let len = body.read(buf)
        let obj = string2JsonObject(String.fromUtf8(buf.slice(0, len)))
        // let content = obj.get("graph").getOrThrow().asString().getValue()
//         let filename = "src/temp/graph.cj"
//         var file: File = File(filename, OpenOption.CreateOrTruncate(true))
//         var content = ###"
// \nfunc graph() {\n    // chain\n    let llm = (getLLMInstance(LLMType.OPEN_AI, model: "gpt-4o-mini") as OpenAI).getOrThrow()\n    let parameters = HashMap<String, Parameter>()\n    let next: Parameter = Parameter("Next", "The next role to act", true)\n    parameters["next"] = next\n    let function_def = BaseFunction("RouteDecider", "Select the next role to act", parameters)\n\n    let tools = ArrayList<BaseTool>([GetWeather()])\n\n    let chain = CoTChain(llm, promptTemplate:SelfDefinePromptTemplate(), tools:tools)\n    chain.bind_function(function_def)\n    let members = ArrayList<String>(["Researcher", "Coder", "Weather"])\n    var options = members.clone()\n    options.append("FINISH")\n    chain.add_prompt("system_message", \n      \"\"\"\n      You are a supervisor tasked with managing a conversation between the\n      following workers: ${members}. Given the following user request,\n      respond with the worker to act next. Each worker will perform a\n      task and respond with their results and status. When finished,\n      respond with FINISH. You must check the above conversation to decide who should act next or finish the conversation.\n      Given the conversation above, who should act next?\n      Or should we FINISH? Select one of: ${options}\n      !!!You must call the tool 'RouteDecider' to help you make the decision. \n      """\n    )\n\n    let supervisor_node = Node("supervisor", "chain", chain)\n    // let input = Dict()\n    // input["text"] = "who should act next?"\n    // let res = supervisor_node.run(input)\n    // println(res)\n\n    // tool\n    let tool = GoogleSearchRun()\n    // let input2 = Dict()\n    // input2.put("query","Dijkstra algorithm")\n    let researcher_node = Node("GoogleSearch", "tool", tool)\n    // let res2 = tool_node.run(input2)\n    // println(res2)\n\n    // agent\n\n    let agent = create_openai_tools_agent(llm, ArrayList<BaseTool>([GetWeather()]))\n    let weather_agent = Node("Weather", "agent", agent)\n\n    let agent3 = create_openai_tools_agent(llm, ArrayList<BaseTool>())\n    let coder_agent = Node("Coder", "agent", agent3)\n\n    \n    // let res3 = weather_agent.run(input3)\n    // println(res3)\n\n    // graph\n    let graph = Graph()\n    graph.addNode(supervisor_node)\n    graph.addNode(weather_agent)\n    graph.addNode(researcher_node)\n    graph.addNode(coder_agent)\n\n    graph.setEntryPoint(supervisor_node)\n\n    graph.addConditionalEdge(supervisor_node, researcher_node)\n    graph.addConditionalEdge(supervisor_node, coder_agent)\n    graph.addConditionalEdge(supervisor_node, weather_agent)\n\n    graph.addEdge(researcher_node, supervisor_node)\n    graph.addEdge(coder_agent, supervisor_node)\n    graph.addEdge(weather_agent, supervisor_node)\n\n    graph.setExitPoint(supervisor_node)\n\n    let input3 = Dict()\n    input3.put("text", "what is the weather like today in Guangzhou?")\n    let res: JsonValue = graph.invoke(input3)\n}"###
//         content = content.replace("\\n", "\n")
//         let bytes: Array<Byte>= content.toArray()
//         file.write(bytes)
//         file.close()
        let res = graph()
        httpContext.responseBuilder.body(res.toString())
    }))
    // 2. 启动服务
    server.serve()
}

main() {
    // let llm = (getLLMInstance(LLMType.OPEN_AI, model: "gpt-4o-mini") as OpenAI).getOrThrow()
    // let codeWriter = CodeWriter(llm)
    // let codeReviewer = CodeReviewer(llm)
    // let codeTester = CodeTester(llm)
    // let input = Dict()
    // input.put("text", """
    // I want to write a calculater program with Python.
    // I have written part of the program:
    // def ADD(a1, a2):
    //     ...

    // def minus(b1, b2):
    //     ...
    // """)

    let url = "https://api.deepseek.com/v1/chat/completions"
    let api_key = "sk-8dd8324c6ad344eea0be1316bdf720c4"

    var header: HttpHeaders = HttpHeaders()
    header.add("Content-Type", "application/json")
    header.add("Authorization", "Bearer ${api_key}")

    var messages = ArrayList<JsonValue>()
    var message = JsonObject()
    message.put("role", JsonString("user"))
    message.put("role", JsonString("user"))
    messages.append(message)

    var body = JsonObject()
    body.put("model", JsonString("deepseek-chat"))
    body.put("messages", message)
    body.put("temperature", JsonFloat(0.7))

    println(body)

    
    // promptgraph()
    return 0
}

// func graph() {
//     // chain
//     let llm = (getLLMInstance(LLMType.OPEN_AI, model: "gpt-4o-mini") as OpenAI).getOrThrow()
//     let parameters = HashMap<String, Parameter>()
//     let next: Parameter = Parameter("Next", "The next role to act", true)
//     parameters["next"] = next
//     let function_def = BaseFunction("RouteDecider", "Select the next role to act", parameters)

//     let tools = ArrayList<BaseTool>([GetWeather()])

//     let chain = CoTChain(llm, promptTemplate:SelfDefinePromptTemplate(), tools:tools)
//     chain.bind_function(function_def)
//     let members = ArrayList<String>(["Researcher", "Coder", "Weather"])
//     var options = members.clone()
//     options.append("FINISH")
//     chain.add_prompt("system_message", 
//       """
//       You are a supervisor tasked with managing a conversation between the
//       following workers: ${members}. Given the following user request,
//       respond with the worker to act next. Each worker will perform a
//       task and respond with their results and status. When finished,
//       respond with FINISH. You must check the above conversation to decide who should act next or finish the conversation.
//       Given the conversation above, who should act next?
//       Or should we FINISH? Select one of: ${options}
//       !!!You must call the tool 'RouteDecider' to help you make the decision. 
//       """
//     )

//     let supervisor_node = Node("supervisor", "chain", chain)
//     // let input = Dict()
//     // input["text"] = "who should act next?"
//     // let res = supervisor_node.run(input)
//     // println(res)

//     // tool
//     let tool = GoogleSearchRun()
//     // let input2 = Dict()
//     // input2.put("query","Dijkstra algorithm")
//     let researcher_node = Node("GoogleSearch", "tool", tool)
//     // let res2 = tool_node.run(input2)
//     // println(res2)

//     // agent

//     let agent = create_openai_tools_agent(llm, ArrayList<BaseTool>([GetWeather()]))
//     let weather_agent = Node("Weather", "agent", agent)

//     let agent3 = create_openai_tools_agent(llm, ArrayList<BaseTool>())
//     let coder_agent = Node("Coder", "agent", agent3)

    
//     // let res3 = weather_agent.run(input3)
//     // println(res3)

//     // graph
//     let graph = Graph()
//     graph.addNode(supervisor_node)
//     graph.addNode(weather_agent)
//     graph.addNode(researcher_node)
//     graph.addNode(coder_agent)

//     graph.setEntryPoint(supervisor_node)

//     graph.addConditionalEdge(supervisor_node, researcher_node)
//     graph.addConditionalEdge(supervisor_node, coder_agent)
//     graph.addConditionalEdge(supervisor_node, weather_agent)

//     graph.addEdge(researcher_node, supervisor_node)
//     graph.addEdge(coder_agent, supervisor_node)
//     graph.addEdge(weather_agent, supervisor_node)

//     graph.setExitPoint(supervisor_node)

//     let input3 = Dict()
//     input3.put("text", "what is the weather like today in Guangzhou?")
//     let res: JsonValue = graph.invoke(input3)
// }