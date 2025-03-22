package canggraph.agent

import canggraph.schema.*
import canggraph.chain.*
import canggraph.llmapi.*
import canggraph.util.{Message, Runnable, ResponseMessage, getMessages}

import encoding.json.*
import std.collection.*

public class PlannerTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX: String = 
            """
            You are a step planner. Your can only make a decision for next step of a task.
            I will give you a question, sometimes with some current progress.
            According the given information, you must choose the most proper one among the following choices to take next step or declare no suitable choice.
            """ 

        let SUFFIX = """
            Begin!
            The input: ${input["message"]}
            The choices are listed as [(`first choice name`, `first agent name`), (`second choice name`, `second agent name`)...]
            Here are choices: ${input["choices"]}
            Your answer must firmly obey the format if one choice chosen: "Next: `agent name`"
            Don't make up any choice ungiven, just declare: "BadRequest: no proper agent found"
        """
        var MAKE_DECISION = ""

        /* multi-role support */
        let system_prompt =  PREFIX + "\n"
        println("system_prompt: ${system_prompt}")
        let user_prompt = SUFFIX + MAKE_DECISION
        println("user_prompt: ${user_prompt}")
        let prompt_obj = JsonObject()
        prompt_obj.put("system", JsonString(system_prompt))
        prompt_obj.put("user", JsonString(user_prompt))
        return prompt_obj.toString()
    }
}

public class Planner <: Runnable {
    public var llm: OpenAI
    public var promptTemplate = PlannerTemplate()

    public init(llm: OpenAI) {
        this.llm = llm
    }

    public func invoke(input: Dict): ResponseMessage {
        let args = input["text"]
        let req = JsonObject()
        req.put("input", JsonString(args))
        req.put("choices", JsonString(input["choices"]))

        if (input.contains("messages")) {
            let msgs = getMessages(input["messages"])
            return invoke(req, msgs)
        }
        return invoke(req)
    }
    

    public func invoke(dict: Dict, messages: ArrayList<Message>): ResponseMessage {
        let obj = JsonObject()
        obj.put("input", JsonString(dict["text"]))
        obj.put("choices", JsonString(dict["choices"]))

        return invoke(obj, messages)
    }

    public func invoke(args: JsonObject, messages: ArrayList<Message>): ResponseMessage {
        println("ARGS: ${args}")
        let prompt: String = args.get("input").getOrThrow().asString().getValue()
        var simple_agent_chain = LLMChain(llm, SimplePromptTemplate())

        let input = Dict()
        input["text"] = prompt
        input["choices"] = args.get("choices").getOrThrow().asString().getValue()
        println("ARGs-Input: ${input.toString()}")

        let input_string = promptTemplate.format(input)

        var response = simple_agent_chain.invoke(input_string, messages)
        return response
    }

    public func invoke(args: JsonObject): ResponseMessage {
        // println("HERE?")
        // println(args)
        let prompt: String = args.get("input").getOrThrow().asString().getValue()
        var simple_agent_chain = LLMChain(llm, SimplePromptTemplate())

        let input = Dict()
        input["text"] = prompt
        input["choices"] = args.get("choices").getOrThrow().asString().getValue()

        let input_string = promptTemplate.format(input)

        var response = simple_agent_chain.invoke(input_string)
        return response
    }
}