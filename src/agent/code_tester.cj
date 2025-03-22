package canggraph.agent

import canggraph.schema.*
import canggraph.chain.*
import canggraph.llmapi.*
import canggraph.util.{Message, Runnable, ResponseMessage, getMessages}

import encoding.json.*
import std.collection.*

public class CodeTesterTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            You are a code tester.
            I will give you a piece of code with description. 
            You should construct some test cases to check whether the code implements the functions.
        """

        let SUFFIX = """
            Begin!
            The code: ${input["text"]}
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

public class CodeTester <: Runnable {
    public var llm: OpenAI
    public var promptTemplate = CodeTesterTemplate() 

    public init(llm: OpenAI) {
        this.llm = llm
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
        var simple_agent_chain = LLMChain(llm, CodeTesterTemplate())

        let input = Dict()
        input["text"] = prompt

        let input_string = promptTemplate.format(input)

        var response = simple_agent_chain.invoke(input_string, messages)
        return response
    }

    public func invoke(args: JsonObject): ResponseMessage {
        let prompt: String = args.get("input").getOrThrow().asString().getValue()
        var simple_agent_chain = LLMChain(llm, CodeTesterTemplate())

        let input = Dict()
        input["text"] = prompt

        let input_string = promptTemplate.format(input)

        var response = simple_agent_chain.invoke(input_string)
        return response
    }
}