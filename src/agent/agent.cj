package canggraph.agent

import canggraph.chain.*
import canggraph.schema.*
import canggraph.tool.*
import canggraph.util.*

import serialization.serialization.*
import std.collection.*
import encoding.json.*

public interface ActionExecutor {
    func executeAction(action: AgentAction): String
}

public class AgentAction {
    public let toolName: String
    public let toolArgs: JsonObject
    
    public init(toolName: String, toolArgs: JsonObject) {
        this.toolName = toolName
        this.toolArgs = toolArgs
    }
}

// public abstract class BaseAgent <: Chain & ActionExecutor{
//     public let tools = ArrayList<BaseTool>()

//     public open func executeAction(action: AgentAction): String {
//         for (tool in tools) {
//             if (tool.name == action.toolName) {
//                 // println("Executing action: ${action.toolName}, input: ${action.input}")
//                 match (action.toolInput) {
//                     case Some(input) =>  
//                         let res = tool.invoke(input)
//                         return res.get("content").getOrThrow().asString().getValue()
//                     case None => 
//                         let res = tool.invoke(action.input)
//                         return res.get("content").getOrThrow().asString().getValue()
//                 }
//             }
//         }
//         // let output = planner.predict()
//         return "Unknown tool: ${action.toolName}"
//     }
// }

public struct StepResult {
    public StepResult(let output: ResponseMessage, let log: String) {}
}

public abstract class Agent <: LLMChain {
    public let agentChain: Chain
    public let agentName: String
    public let agentDescription: String
    // public let outputParser: OutputParser<ResponseMessage>
    // public let tools = ArrayList<BaseTool>()
    
    public init(agentChain: Chain, tools: ArrayList<BaseTool>, name!: String = "", description!: String = "") {
        this.agentChain = agentChain
        this.agentName = name
        this.agentDescription = description
        // this.outputParser = outputParser
        this.tools.appendAll(tools)
    }

    // public init(planner: Chain, tools: ArrayList<BaseTool>) {
    //     this.planner = planner
    //     this.outputParser = MockOutputParser<ResponseMessage>()
    //     this.tools.appendAll(tools)
    // }

}
