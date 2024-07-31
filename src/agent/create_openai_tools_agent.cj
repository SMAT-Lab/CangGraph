package agent
import chain.*
import llmapi.*

public class CallToolsPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            You are an openai tool call agent. You have access to the following tools: ${input["tool_names"]}.
            Here're the description of the tools: ${input["tool_with_descriptions"]}.
            I will give you a question, and if there's a tool which can be used to solve the question, you should choose it.
        """

        let SUFFIX = """
            Begin!
            The input: ${input["text"]}
        """
        /* multi-role support */
        let system_prompt =  PREFIX + "\n"
        let user_prompt = SUFFIX
        let prompt_obj = JsonObject()
        prompt_obj.put("system", JsonString(system_prompt))
        prompt_obj.put("user", JsonString(user_prompt))
        return prompt_obj.toString()
    }
}

public func callFunc(res: JsonObject): Bool {
    match (res.get("message")) {
        case None => return true
        case Some(_) => return false
    }
}

public func executeTools(action: AgentAction, tools: ArrayList<BaseTool>): String {
    for (tool in tools) {
        if (tool.name == action.toolName) {
            // println("Executing action: ${action.toolName}, input: ${action.input}")
            match (action.toolInput) {
                case Some(input) =>  
                    return tool.invoke(input)
                case None => return (tool.run([action.input]) as String).getOrThrow()
            }
        }
    }
    // let output = planner.predict()
    return "Unknown tool: ${action.toolName}"
}

public class create_openai_tools_agent <: Runnable{
    public var llm: OpenAI
    public var tools: ArrayList<BaseTool>

    public init(llm: OpenAI, tools: ArrayList<BaseTool>) {
        this.llm = llm
        this.tools = tools
    }

    public func run(args : Array<Any>) : Any {}

    public func invoke(args: JsonObject): String {
        "unimplemented"
    }

    public func invoke(dict: Dict): JsonObject {
        let prompt: String = dict["input"]
        var openai_tools_agent_chain = LLMChain(llm, CallToolsPromptTemplate())
        var schema_tools: ArrayList<JsonValue> = ArrayList()
        for (tool in tools) {
            schema_tools.append(tool.args_schema.getOrThrow())
        }

        let input = Dict()
        input["text"] = prompt
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
        // println(schema_tools)
        var res = openai_tools_agent_chain.function_call(input, schema_tools)
        if (callFunc(res) == false) {
            let ret = JsonObject()
            ret.put("content", res["message"])
            return ret
        } else {
            let function_name = res.get("function_name").getOrThrow().asString().getValue()
            let function_args = res.get("function_args").getOrThrow().asString().getValue()
            let value: JsonObject = JsonValue.fromStr(function_args).asObject()
            let action: AgentAction = AgentAction(function_name, value)
            let ob: String = executeTools(action, tools)
            let ret = JsonObject()
            ret.put("content", JsonString(ob))
            return ret
        }
    }
}