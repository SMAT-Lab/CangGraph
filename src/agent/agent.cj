package agent
from std import collection.*
import chain.*
import schema.*
import tool.*
import util.*
from serialization import serialization.*
from encoding import json.*

// public interface ActionExecutor {
//     func executeAction(action: AgentAction): String
// }

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
    public let planner: Chain
    // public let outputParser: OutputParser<ResponseMessage>
    // public let tools = ArrayList<BaseTool>()
    
    public init(planner: Chain, tools: ArrayList<BaseTool>) {
        this.planner = planner
        // this.outputParser = outputParser
        this.tools.appendAll(tools)
    }

    // public init(planner: Chain, tools: ArrayList<BaseTool>) {
    //     this.planner = planner
    //     this.outputParser = MockOutputParser<ResponseMessage>()
    //     this.tools.appendAll(tools)
    // }

}
