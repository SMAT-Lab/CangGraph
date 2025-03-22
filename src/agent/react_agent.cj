package canggraph.agent

import canggraph.schema.*
import canggraph.chain.{LLMChain}
import canggraph.llmapi.*
import canggraph.tool.BaseTool
import canggraph.util.{FunctionInfo, Message, Runnable, ResponseMessage, ToolCallMessage, getMessages}

import encoding.json.*
import std.{collection.*, unicode.*}
import serialization.serialization.*

public class ReActPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            Answer the following questions as best you can. You have access to the following tools:"""

        let FORMAT_INSTRUCTIONS = """
            
            ${input["tool_names"]}

            The descriptions of the tools are follow:
            ${input["tool_with_descriptions"]}

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
    public init(tools: ArrayList<BaseTool>) {
        super(getLLMInstance(LLMType.OPEN_AI, model:"gpt-4o-mini"), ReActPromptTemplate(), tools)
    }
}

public class ReActAgent <: Agent & ActionExecutor {
    public init(tools: ArrayList<BaseTool>) {
        super(ReActChain(tools), tools)
        println("ReActAgent init done.")
    }

    public func constructInput(scratchpad: Dict): Dict {
        let input = Dict()
        input["text"] = scratchpad["text"]
        input
    }

    public func shouldContinue(res: ResponseMessage): Bool {
        let obj = (res.serialize().toJson() as JsonObject).getOrThrow()
        let tool_call = obj.get("tool_call").getOrThrow().asBool().getValue()
        return tool_call
    }

    public func invoke(message: String): ResponseMessage {
        let input = Dict()
        let messages = ArrayList<Message>()
        input["text"] = message
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

        var res: ResponseMessage = agentChain.invoke(input)
        while(shouldContinue(res)) {
            let toolCalls = (res.serialize().toJson() as JsonObject).getOrThrow().get("tool_calls").getOrThrow().asArray()
            for (i in 0..toolCalls.size()) {
                let toolCall = toolCalls[i].asObject()
                let toolName: String = toolCall.get("name").getOrThrow().asString().getValue()
                let toolArgs: JsonObject = toolCall.get("arguments").getOrThrow().asObject()
                let tool_ids: String = "1" //toolCall.get("id").getOrThrow().asString().getValue()

                let action = AgentAction(toolName, toolArgs)
                let toolResponse = executeAction(action)
                let function = JsonObject()
                function.put("name", JsonString(toolName))
                function.put("arguments", toolArgs)

                let toolCallMessage = ToolCallMessage(tool_ids, FunctionInfo(toolName, ""), "function")
                let toolMessage = Message("assistant")
                toolMessage.add_tool_calls(toolCallMessage)
                messages.append(toolMessage)
                
                let resultMessage = Message("tool", toolResponse)
                resultMessage.set_tool_call_id(tool_ids)
                messages.append(resultMessage)
            }
            println(messages.serialize().toJson())
            res = agentChain.invoke(input, messages)
        }
        return res
    }

    public func executeAction(action: AgentAction): String {
        for (tool in tools) {
            if (tool.name == action.toolName) {
                let res: ResponseMessage = tool.invoke(action.toolArgs.toString())
                return res.serialize().toJson().asObject().get("content").getOrThrow().asString().getValue()
            }
        }
        return "Unknown tool: ${action.toolName}"
    }
}
