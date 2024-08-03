package agent
from encoding import json.*
from std import unicode.*
import llmapi.*

public class ReActPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            Answer the following questions as best you can. You have access to the following tools:"""

        let FORMAT_INSTRUCTIONS = """
            
            ${input["tool_names"]}

            The descriptions of the tools are follow:
            ${input["tool_with_descriptions"]}

            Use the following format:

            Question: the input question you must answer
            Thought: you should always think about what to do
            Action: the action to take, should be one of ${input["tool_names"]}
            Action Input: the input to the action
            Observation: the result of the action
            ... (this Thought/Action/Action Input/Observation can repeat N times)
            Thought: I now know the final answer
            Final Answer: the final answer to the original input question
        """

        let SUFFIX = """
            Begin!
            Question: ${input["text"]}
            Thought:     
        """
        /* multi-role support */
        return  PREFIX + "\n" + FORMAT_INSTRUCTIONS + "\n" + SUFFIX
    }
}

public class ReActChain <: LLMChain {
    public init() {
        super(OpenAI(), ReActPromptTemplate())
    }
}

public class ReActAgent <: Agent {
    public init(tools: ArrayList<BaseTool>) {
        super(ReActChain(), ReActAgentOutputParser(), tools)
        println("ReActAgent init done.")
    }
    public override func constructAgentScratchpad(input: Dict, intermediateSteps: ArrayList<StepResult>, stepCount: Int64): Dict {
        println("ReActAgent: takeNextStep(${stepCount})")
        let scratchpad = Dict()
        scratchpad["text"] = ""
        let toolNamesList  = collectArrayList(map({tool:BaseTool => tool.name})(tools))
        var toolNames = ""
        for (toolName in toolNamesList) {
            toolNames += toolName + ", "
        }
       
        let toolDescriptionsList  = collectArrayList(map({tool:BaseTool => tool.description})(tools)) 
        var toolWithDescriptions = ""
        for (toolDescription in toolDescriptionsList) {
            toolWithDescriptions += toolDescription + ", "
        }

        scratchpad["tool_names"] = toolNames
        scratchpad["tool_with_descriptions"] = toolWithDescriptions
        scratchpad["step_count"] = stepCount.toString()
        println("intermediateSteps: ${intermediateSteps.size}")
        for (stepResult in intermediateSteps) {
            let output = stepResult.output
            let log = stepResult.log
            scratchpad["text"] += "Step: "; scratchpad["text"] += stepCount.toString(); scratchpad["text"] += "\n"
            scratchpad["text"] += log + "\n"
            match (output) {
                case Finish(text) => 
                    scratchpad["text"] += "Result: "; scratchpad["text"] += text
                case Action(action) => scratchpad["text"] += "Observation: "; scratchpad["text"] += action.observation ?? "No observation" ; scratchpad["text"] += "\n"
                case Actions(actions) => 
                    for (action in actions) {
                        scratchpad["text"] += "Observation: "
                        scratchpad["text"] += action.observation ?? "No observation" ; scratchpad["text"] += "\n"
                    }
            }
        }
        scratchpad["text"] += input["text"]
        scratchpad
    }

    public func constructInput(scratchpad: Dict): Dict {
        let input = Dict()
        input["text"] = scratchpad["text"]
        input
    }

    public func shouldContinue(res: JsonObject): Bool {
        match (res.get("message")) {
            case None => return true
            case Some(_) => return false
        }
    }

    public func generate(text: String): String {
        var schema_tools: ArrayList<JsonValue> = ArrayList()
        for (tool in tools) {
            schema_tools.append(tool.args_schema.getOrThrow())
        }
        let input = Dict()
        input["text"] = text
        let toolNamesList  = collectArrayList(map({tool:BaseTool => tool.name})(tools))
        var toolNames = ""
        for (toolName in toolNamesList) {
            toolNames += toolName + ", "
        }
        input["tool_names"] = toolNames

        let toolDescriptionsList  = collectArrayList(map({tool:BaseTool => tool.description})(tools))
        var toolWithDescriptions = ""
        for (i in 0..toolDescriptionsList.size) {
            toolWithDescriptions += toolNamesList[i] + ": " + toolDescriptionsList[i] + ", "
        }
        input["tool_with_descriptions"] = toolWithDescriptions

        var res = ReActChain().function_call(input, schema_tools)
        var ans: String = ""
        while (shouldContinue(res)){
            let function_name = res.get("function_name").getOrThrow().asString().getValue()
            let function_args = res.get("function_args").getOrThrow().asString().getValue()
            let value: JsonObject = JsonValue.fromStr(function_args).asObject()
            let action: AgentAction = AgentAction(function_name, value)
            let ob: String = executeAction(action)
            var msg: String = ReActChain().generate_react(input)

            msg += "Observation: ${ob}\n"
            ans += msg
            input["text"] += msg
            res = ReActChain().function_call(input, schema_tools)
        }

        ans += res.get("message").getOrThrow().asString().getValue()

        return ans
        
    }

}
