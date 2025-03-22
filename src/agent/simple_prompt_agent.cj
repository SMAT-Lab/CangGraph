package canggraph.agent

import canggraph.chain.*
import canggraph.schema.*
import canggraph.llmapi.*
import canggraph.util.*

import encoding.json.*
import std.collection.*

public class SimplePromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX: String
        println("Input: ${input.toString()}")
        if (input["prompt"] == "") {
            PREFIX = 
            """
            You are an openai agent.
            I will give you a question.
            """ 
        } else {
            PREFIX = input["prompt"]
        }

        let SUFFIX = """
            Begin!
            The input: ${input["text"]}
        """
        /* multi-role support */
        let system_prompt =  PREFIX + "\n"
        println("system_prompt: ${system_prompt}")
        let user_prompt = SUFFIX
        println("user_prompt: ${user_prompt}")
        let prompt_obj = JsonObject()
        prompt_obj.put("system", JsonString(system_prompt))
        prompt_obj.put("user", JsonString(user_prompt))
        return prompt_obj.toString()
    }
}

public class simple_prompt <: Runnable {
    public var llm: OpenAI
    public var promptTemplate = SimplePromptTemplate()
    public var selfDifinedPrompt: String

    public init(llm: OpenAI, selfDifinedPrompt!: String = "") {
        this.llm = llm
        this.selfDifinedPrompt = selfDifinedPrompt
    }

    public func invoke(input: Dict): ResponseMessage {
        println("SPa: ${input.toString()}")
        let args = input["text"]
        let req = JsonObject()
        req.put("input", JsonString(args))

        if (input.contains("messages")) {
            let msgs = getMessages(input["messages"])
            for (msg in msgs) {
                println("MSG: ${msg.toString()}")
            }
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
        println("THERE?")
        println(args)
        let prompt: String = args.get("input").getOrThrow().asString().getValue()
        var simple_agent_chain = LLMChain(llm, SimplePromptTemplate())

        let input = Dict()
        input["text"] = prompt
        input["prompt"] = selfDifinedPrompt
 
        let input_string = promptTemplate.format(input)

        var response = simple_agent_chain.invoke(input_string, messages)
        return response
    }

    public func invoke(args: JsonObject): ResponseMessage {
        println("HERE?")
        println("HEREargs: ${args}")
        let prompt: String = args.get("input").getOrThrow().asString().getValue()
        var simple_agent_chain = LLMChain(llm, SimplePromptTemplate())

        let input = Dict()
        input["text"] = prompt
        input["prompt"] = selfDifinedPrompt

        let input_string = promptTemplate.format(input)

        var response = simple_agent_chain.invoke(input_string)
        return response
    }
}