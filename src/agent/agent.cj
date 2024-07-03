package agent
from std import collection.*
import chain.*
import schema.*
import tool.*
//type Dict = HashMap<String, String>
public struct AgentDescription {
    let name: String
    let description: String

    public init(name: String, description: String) {
        this.name = name
        this.description = description
    }
}

public struct AgentAction {
    let toolName: String
    public var agentName: Option<String> = None
    public var input: String
    public var toolInput: Option<JsonObject> = None
    public var nextAgent: Option<String> = None

    public init(toolName: String, input: String) {
        this.toolName = toolName
        this.input = input
    }

    public init(toolName: String, toolInput: JsonObject) {
        this.toolName = toolName
        this.toolInput = Some(toolInput)
        this.input = toolInput.toString()
    }

    public init(toolName: String, agentName: String, input: String) {
        this.toolName = toolName
        this.agentName = agentName
        this.input = input
    }

    public init(toolName: String, agentName: String, input: String, nextAgent: String) {
        this.toolName = toolName
        this.agentName = agentName
        this.input = input
        this.nextAgent = Some(nextAgent)
    }

    public var observation: Option<String> = None
    public var fileName : Option<String> = None
}

public enum AgentOutput {
    | Action(AgentAction)
    | Actions(ArrayList<AgentAction>)
    | Finish(String)
}

public interface ActionExecutor {
    func executeAction(action: AgentAction): String
}

public abstract class BaseAgent <: Chain & ActionExecutor {
    public let tools = ArrayList<BaseTool>()

    public open func executeAction(action: AgentAction): String {
        for (tool in tools) {
            if (tool.name == action.toolName) {
                // println("Executing action: ${action.toolName}, input: ${action.input}")
                match (action.toolInput) {
                    case Some(input) => 
                        return tool.run(input)
                    case None => return tool.run(action.input)
                }
            }
        }
        // let output = planner.predict()
        return "Unknown tool: ${action.toolName}"
    }
}

public struct StepResult {
    public StepResult(let output: AgentOutput, let log: String) {}
}

public abstract class Agent <: BaseAgent {
    public let planner: Chain
    public let outputParser: OutputParser<AgentOutput>
    // public let tools = ArrayList<BaseTool>()
    
    public init(planner: Chain, outputParser: OutputParser<AgentOutput>, tools: ArrayList<BaseTool>) {
        this.planner = planner
        this.outputParser = outputParser
        this.tools.appendAll(tools)
    }

    public open func constructAgentScratchpad(input: Dict, intermediateSteps: ArrayList<StepResult>, stepCount: Int64): Dict;
    
    public open func takeNextStep(input: Dict, intermediateSteps: ArrayList<StepResult>, stepCount: Int64): StepResult {
        // println("takeNextStep(${stepCount})")
        let agentScratchpad: Dict = constructAgentScratchpad(input, intermediateSteps, stepCount)
        let log: Dict = planner.predict(agentScratchpad)
        let output: AgentOutput = outputParser.parse(log)
        let executeOutput: AgentOutput = match (output) {
            case Action(action) => 
                var newAction = action
                newAction.observation = executeAction(action)
                Action(newAction)
            
            case Actions(actions) => 
                let actionList = ArrayList<AgentAction>()
                for (action in actions) {
                    var newAction = action
                    newAction.observation = Some(executeAction(action))
                    actionList.append(newAction)
                }
                Actions(actionList)
            
            case Finish(result) =>              
                Finish(result) 
        }
        return StepResult(executeOutput, log["text"])
    }

    public func shouldContinue(intermediateSteps: ArrayList<StepResult>): Bool {
        if (intermediateSteps.size == 0) {
            return true
        }
        return match (intermediateSteps[intermediateSteps.size - 1].output) {
            case Finish(_) => false
            case _ => true
        }
    }

    public func generateOutputs(intermediateSteps: ArrayList<StepResult>): Dict {
        let output = Dict()

        output["log"] = ""
        for (step in intermediateSteps) {
            output["log"] += step.log + "\n"
        }
        output["text"] = match(intermediateSteps[intermediateSteps.size - 1].output) {
            case Finish(result) => result
            case _ => throw Exception("The last step should be a Finish step.")
        }    
        return output
    }

    public open func generate(inputs: Collection<Dict>): Collection<Dict> {
        let outputs = ArrayList<Dict>()
        for (input in inputs) {
            let intermediateSteps = ArrayList<StepResult>()
            var stepCount = 0
            while(this.shouldContinue(intermediateSteps)) {
                stepCount += 1
                let stepResult: StepResult = this.takeNextStep(input, intermediateSteps, stepCount)
                // let executeOutput: AgentOutput = stepResult.output
                // let log: String = stepResult.log
                intermediateSteps.append(stepResult)
            }
            outputs.append(this.generateOutputs(intermediateSteps))
        }
        return outputs
    }
}
