package canggraph.agent

import canggraph.chain.*
import canggraph.schema.*
import canggraph.llmapi.*
import canggraph.tool.BaseTool
import canggraph.util.*

import encoding.json.*
import std.collection.*

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

public class create_openai_tools_agent <: Runnable {
    public var llm: OpenAI
    public var tools: ArrayList<BaseTool>
    public var promptTemplate = CallToolsPromptTemplate() 
    public var openai_tools = ArrayList<Tool>()

    public init(llm: OpenAI, tools: ArrayList<BaseTool>) {
        this.llm = llm
        this.tools = tools
        for (tool in tools) {
            this.openai_tools.append(tool.tool)
        }
    }

    public func invoke(input: Dict): ResponseMessage {
        let args = input["text"]
        let req = JsonObject()
        req.put("input", JsonString(args))

        if (input.contains("messages")) {
            let msgs = getMessages(input["messages"])
            return invoke(req, msgs)
        }
        return invoke(req)
    }
    

    public func invoke(dict: Dict, messages: ArrayList<Message>): ResponseMessage {
        let obj = JsonObject()
        obj.put("input", JsonString(dict["text"]))

        return invoke(obj, messages)
    }
    public func invoke(args: JsonObject, messages: ArrayList<Message>): ResponseMessage {
        let prompt: String = args.get("input").getOrThrow().asString().getValue()
        var openai_tools_agent_chain = LLMChain(llm, CallToolsPromptTemplate(), tools)

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

        let input_string = promptTemplate.format(input)

        var response = openai_tools_agent_chain.invoke(input_string, messages)
        var res: JsonObject = (response.serialize().toJson() as JsonObject).getOrThrow()

        if (res.get("tool_call").getOrThrow().asBool().getValue() == false) {
            return response
        } else {
            let functions = res["tool_calls"].asArray()
            var ob: String = ""
            for (i in 0..functions.size()) {
                let function = functions[i].asObject()
                let toolName = function["name"].asString().getValue()
                let toolInput = function["arguments"].asObject().toString()
                for (tool in tools) {
                    if (tool.name == toolName) {
                        let tool_res: ResponseMessage = tool.invoke(toolInput)
                        ob += (tool_res.serialize().toJson() as JsonObject).getOrThrow().get("content").getOrThrow().asString().getValue()
                    }
                }
            }
            let ret = ResponseMessage("tool", ob, false, Array<ToolCall>())
            return ret
        }
    }

    public func invoke(args: JsonObject): ResponseMessage {
        let prompt: String = args.get("input").getOrThrow().asString().getValue()
        var openai_tools_agent_chain = LLMChain(llm, CallToolsPromptTemplate(), tools)

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

        let input_string = promptTemplate.format(input)

        var response = openai_tools_agent_chain.invoke(input_string)
        var res: JsonObject = (response.serialize().toJson() as JsonObject).getOrThrow()

        if (res.get("tool_call").getOrThrow().asBool().getValue() == false) {
            return response
        } else {
            let functions = res["tool_calls"].asArray()
            var ob: String = ""
            for (i in 0..functions.size()) {
                let function = functions[i].asObject()
                let toolName = function["name"].asString().getValue()
                let toolInput = function["arguments"].asObject().toString()
                for (tool in tools) {
                    if (tool.name == toolName) {
                        let tool_res: ResponseMessage = tool.invoke(toolInput)
                        ob += (tool_res.serialize().toJson() as JsonObject).getOrThrow().get("content").getOrThrow().asString().getValue()
                    }
                }
            }
            let ret = ResponseMessage("tool", ob, false, Array<ToolCall>())
            return ret
        }
    }
}