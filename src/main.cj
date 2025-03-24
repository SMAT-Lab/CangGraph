package canggraph

import canggraph.multi.*
import canggraph.examples.*

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

// func startServer(): Unit {
//     // 1. 构建 Server 实例
//     let server = ServerBuilder()
//                         .addr("127.0.0.1")
//                         .port(8081)
//                         .build()
//     var a: HttpRequestHandler = FuncHandler({ httpContext =>
//         httpContext.responseBuilder.body("index")
//     })
//     var b: HttpRequestHandler = FuncHandler({ httpContext =>
//         httpContext.responseBuilder.body("id")
//     })
//     var c: HttpRequestHandler = FuncHandler({ httpContext =>
//         httpContext.responseBuilder.body("help")
//     })
//     server.distributor.register("/index", a)
//     server.distributor.register("/id", b)
//     server.distributor.register("/help", c)
//     server.distributor.register("/graph", FuncHandler({ httpContext =>
//         let request = httpContext.request
//         if (request.method != "POST") {
//             httpContext.responseBuilder.body("Method not allowed")
//             return
//         }
//         let body = request.body
        
//         let buf = Array<UInt8>(10000000, item: 0)
//         let len = body.read(buf)
//         let obj = string2JsonObject(String.fromUtf8(buf.slice(0, len)))
//         // let content = obj.get("graph").getOrThrow().asString().getValue()
// //         let filename = "src/temp/graph.cj"
// //         var file: File = File(filename, OpenOption.CreateOrTruncate(true))
// //         var content = ###"
// // \nfunc graph() {\n    // chain\n    let llm = (getLLMInstance(LLMType.OPEN_AI, model: "gpt-4o-mini") as OpenAI).getOrThrow()\n    let parameters = HashMap<String, Parameter>()\n    let next: Parameter = Parameter("Next", "The next role to act", true)\n    parameters["next"] = next\n    let function_def = BaseFunction("RouteDecider", "Select the next role to act", parameters)\n\n    let tools = ArrayList<BaseTool>([GetWeather()])\n\n    let chain = CoTChain(llm, promptTemplate:SelfDefinePromptTemplate(), tools:tools)\n    chain.bind_function(function_def)\n    let members = ArrayList<String>(["Researcher", "Coder", "Weather"])\n    var options = members.clone()\n    options.append("FINISH")\n    chain.add_prompt("system_message", \n      \"\"\"\n      You are a supervisor tasked with managing a conversation between the\n      following workers: ${members}. Given the following user request,\n      respond with the worker to act next. Each worker will perform a\n      task and respond with their results and status. When finished,\n      respond with FINISH. You must check the above conversation to decide who should act next or finish the conversation.\n      Given the conversation above, who should act next?\n      Or should we FINISH? Select one of: ${options}\n      !!!You must call the tool 'RouteDecider' to help you make the decision. \n      """\n    )\n\n    let supervisor_node = Node("supervisor", "chain", chain)\n    // let input = Dict()\n    // input["text"] = "who should act next?"\n    // let res = supervisor_node.run(input)\n    // println(res)\n\n    // tool\n    let tool = GoogleSearchRun()\n    // let input2 = Dict()\n    // input2.put("query","Dijkstra algorithm")\n    let researcher_node = Node("GoogleSearch", "tool", tool)\n    // let res2 = tool_node.run(input2)\n    // println(res2)\n\n    // agent\n\n    let agent = create_openai_tools_agent(llm, ArrayList<BaseTool>([GetWeather()]))\n    let weather_agent = Node("Weather", "agent", agent)\n\n    let agent3 = create_openai_tools_agent(llm, ArrayList<BaseTool>())\n    let coder_agent = Node("Coder", "agent", agent3)\n\n    \n    // let res3 = weather_agent.run(input3)\n    // println(res3)\n\n    // graph\n    let graph = Graph()\n    graph.addNode(supervisor_node)\n    graph.addNode(weather_agent)\n    graph.addNode(researcher_node)\n    graph.addNode(coder_agent)\n\n    graph.setEntryPoint(supervisor_node)\n\n    graph.addConditionalEdge(supervisor_node, researcher_node)\n    graph.addConditionalEdge(supervisor_node, coder_agent)\n    graph.addConditionalEdge(supervisor_node, weather_agent)\n\n    graph.addEdge(researcher_node, supervisor_node)\n    graph.addEdge(coder_agent, supervisor_node)\n    graph.addEdge(weather_agent, supervisor_node)\n\n    graph.setExitPoint(supervisor_node)\n\n    let input3 = Dict()\n    input3.put("text", "what is the weather like today in Guangzhou?")\n    let res: JsonValue = graph.invoke(input3)\n}"###
// //         content = content.replace("\\n", "\n")
// //         let bytes: Array<Byte>= content.toArray()
// //         file.write(bytes)
// //         file.close()
//         let res = graph()
//         httpContext.responseBuilder.body(res.toString())
//     }))
//     // 2. 启动服务
//     server.serve()
// }

main() {
    toolCall()
    return 0
}