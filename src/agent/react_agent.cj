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
        super(getLLMInstance(LLMType.OPEN_AI, model:"gpt-4o-mini"), ReActPromptTemplate())
    }
}

public class ReActAgent <: Agent {
    public init(tools: ArrayList<BaseTool>) {
        super(ReActChain(), tools)
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


    // public func invoke(args: JsonObject): ResponseMessage {
    //     let prompt: String = args.get("input").getOrThrow().asString().getValue()

    //     let input = Dict()
    //     input["text"] = prompt
    //     let toolNamesList  = collectArrayList(map({tool:BaseTool => tool.name})(tools))
    //     var toolNames = ""
    //     for (toolName in toolNamesList) {
    //         toolNames += toolName + ", "
    //     }
    //     input["tool_names"] = toolNames

    //     let toolDescriptionsList  = collectArrayList(map({tool:BaseTool => tool.description})(tools))
    //     var toolWithDescriptions = ""
    //     for (i in 0..toolDescriptionsList.size) {
    //         toolWithDescriptions += toolNamesList[i] + ": " + toolDescriptionsList[i] + ", "
    //     }
    //     input["tool_with_descriptions"] = toolWithDescriptions

    //     var res: ResponseMessage = planner.invoke(input)
    //     while(shouldContinue(res)) {
    //         let toolCalls = (res.serialize().toJson() as JsonObject).getOrThrow().get("tool_calls").getOrThrow().asArray()
    //         for (i in 0..toolCalls.size()) {
    //             //
    //         }
    //     }
    //     return res
    // }
}
