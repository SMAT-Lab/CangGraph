package agent
from encoding import json.*
from std import regex.*

import llmapi.*

public class FileWriterOutputParser <: OutputParser<AgentOutput> {
    public override func parse(output: Dict): AgentOutput {
        let text: String = output["text"]
        let lines = text.split("\n")
        var action: String = ""
        var actionInput: Option<String> = None
        var fileName: String = ""
        for (line in lines) {
            if (line.startsWith("Action:")) {
                action = line.split(":")[1].trim()
            } else if (line.startsWith("File Name:")) {
                fileName = line.split(":")[1].trim()
            }
            else if (line.startsWith("Action Input:")) {
                actionInput = Some(line.split(":")[1].trim())
            } 
            else {
                match(actionInput) {
                    case Some(input) => actionInput = Some(input + "\n" + line)
                    case None => actionInput = None
                }
            }
        }
        if(action == "") {
            return Finish(output["text"])
        }
        var ret = AgentAction(action, actionInput.getOrThrow())
        ret.fileName = fileName
        println("Action: ${ret.toolName}, File Name: ${ret.fileName}")
        return Action(ret)
    }
}

public class DocWriterPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            You are the best document writer who can write the document according to the tasks. 
            !!! You don't need to write the code, you only write the document
            You have access to the following tools:
            ${input["tool_names"]}
        """
        let FORMAT_INSTRUCTIONS = """
            Use the following format:
            Question: the task
            Agent's Answer: I have saved the document to a file
        """

        let SUFFIX = """
            Begin!
            Question: ${input["text"]}
        """
        /* multi-role support */
        let system_prompt =  PREFIX + "\n" + FORMAT_INSTRUCTIONS + "\n"
        let user_prompt = SUFFIX
        let prompt_obj = JsonObject()
        prompt_obj.put("system", JsonString(system_prompt))
        prompt_obj.put("user", JsonString(user_prompt))
        return prompt_obj.toString()
    }
}

public class DocWriterChain <: LLMChain {
    public init() {
        super(OpenAI(), DocWriterPromptTemplate())
    }
}

public class DocWriterAgent <: Role {
    public init(tools!: ArrayList<BaseTool> = ArrayList<BaseTool>([FileSaver()]), agents!: ArrayList<Role> = ArrayList<Role>()) {
        super("Doc_Writer", "When having a task, you use the agent to write the document according to the task", DocWriterChain(), FileWriterOutputParser(), tools: tools, agents: agents)
        setArgs()
        println("DocWriterAgent init done.")
    }
    public override func takeNextStep(input: Dict, intermediateSteps: ArrayList<StepResult>, stepCount: Int64): StepResult {
        println("${this.role}: takeNextStep(${stepCount})")
        try {
            let agentScratchpad: Dict = constructAgentScratchpad(input, intermediateSteps, stepCount)
            let log: Dict = planner.predict(agentScratchpad)
            var output: AgentOutput = outputParser.parse(log)
            let executeOutput: AgentOutput = match (output) {
                case Action(action) => 
                    var newAction = action
                    newAction.observation = executeAction(action)
                    // Action(newAction)
                    Finish(newAction.observation.getOrThrow())

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

        var res = DocWriterChain().function_call(input, schema_tools)

        let function_name = res.get("function_name").getOrThrow().asString().getValue()
        let function_args = res.get("function_args").getOrThrow().asString().getValue()
        let value: JsonObject = JsonValue.fromStr(function_args).asObject()
        let action: AgentAction = AgentAction(function_name, value)
        
        executeAction(action)
        input["text"] += "Observation: I have saved the document to ${value.get("filename").getOrThrow()}\n"

        let msg: String = DocWriterChain().generate_react(input)
        let lines = msg.split("\n")
        var ret = ""
        for (line in lines) {
            if (line.startsWith("Agent's Answer:")) {
                ret = line.split(":")[1].trim()
            }
        }
        return ret
        
    }
}