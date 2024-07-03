package agent
from std import collection.*
import chain.*
import schema.*
import tool.*
public abstract class Role <: Agent {
    public let role: String
    public let description: String
    public let agents: ArrayList<Role>
    public var args_schema: JsonObject = JsonObject()

    public init(role: String, description: String, planner: Chain, outputParser: OutputParser<AgentOutput>, tools!: ArrayList<BaseTool> = ArrayList<BaseTool>(), agents!: ArrayList<Role> = ArrayList<Role>()) {
        super(planner, outputParser, tools)
        this.description = description
        this.role = role
        this.agents = agents
    }

    public open func generate(input: String): String{
        var output = super.predict(input)["text"]
        try {
            output = output.split("Agent's Final Answer:")[1].trim()
        } catch (e: Exception) {
            output = output
        }
        return output

    }
    public open func generate(input: Dict): String{
        var output = super.predict(input["text"])["text"]
        try {
            output = output.split("Agent's Final Answer:")[1].trim()
        } catch (e: Exception) {
            output = output
        }
        return output
    }

    public open override func takeNextStep(input: Dict, intermediateSteps: ArrayList<StepResult>, stepCount: Int64): StepResult {
        println("${this.role}: takeNextStep(${stepCount})")
        try {
            let agentScratchpad: Dict = constructAgentScratchpad(input, intermediateSteps, stepCount)
            let log: Dict = planner.predict(agentScratchpad)
            var output: AgentOutput = outputParser.parse(log)
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
            let res = StepResult(executeOutput, log["text"])
            return res
        } catch (error: Exception) {
            // println("Error: ${error}")
            // return StepResult(Finish("Error: ${error}"), "Error: ${error}")
            this.takeNextStep(input, intermediateSteps, stepCount)
        }
    }
    
    public open override func constructAgentScratchpad(input: Dict, intermediateSteps: ArrayList<StepResult>, stepCount: Int64): Dict {
        let scratchpad = Dict()
        let toolNamesList  = collectArrayList(map({tool:BaseTool => tool.name})(tools))
        var toolNames = ""
        for (toolName in toolNamesList) {
            toolNames += toolName + ", "
        }
        scratchpad["text"] = stepCount.toString()
        scratchpad["tool_names"] = toolNames

        scratchpad["agent_scratchpad"] = ""

        for (stepResult in intermediateSteps) {
            let output = stepResult.output
            let log = stepResult.log
            scratchpad["agent_scratchpad"] += log + "\n"
            match (output) {
                case Finish(text) => scratchpad["agent_scratchpad"] += "Result: "; scratchpad["agent_scratchpad"] += text
                case Action(action) =>     
                    scratchpad["agent_scratchpad"] += "Observation: "; scratchpad["agent_scratchpad"] += action.observation ?? "No observation" ; scratchpad["agent_scratchpad"] += "\n"
                case Actions(actions) => 
                    for (action in actions) {
                        scratchpad["agent_scratchpad"] += "Observation: "
                        scratchpad["agent_scratchpad"] += action.observation ?? "No observation" ; scratchpad["agent_scratchpad"] += "\n"
                    }
            }
        }
        scratchpad["text"] += input["text"]
        scratchpad
    }

    public func setArgs() {
        var query = JsonObject()
        query.put("type", JsonString("string"))
        query.put("description", JsonString("the input to the ${this.role} agent"))

        var properties = JsonObject()
        properties.put("query", query)

        var required = JsonArray()
        required.add(JsonString("query"))

        var parameters = JsonObject()
        parameters.put("type", JsonString("object"))
        parameters.put("properties", properties)
        parameters.put("required", required)

        var function = JsonObject()
        function.put("name", JsonString(this.role))
        function.put("description", JsonString(this.description))
        function.put("parameters", parameters)

        var args = JsonObject()
        args.put("type", JsonString("function"))
        args.put("function", function)

        this.args_schema = args
    }
}