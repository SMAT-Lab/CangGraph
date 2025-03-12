package canggraph.agent

public class BranchPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            You are a choice maker. 
            According the situation, you have to choose the most proper one among given choices.
            You must not make up non-existent choices.
            Your answer must follow the "Output" format:
            For example, after writing code, the next logical step is to verify its functionality.
            With choices {"code_writing", "code_testing", "end"}
            Output: "code_testing"
        """

        let SUFFIX = """
            Begin!
            The situation: ${input["text"]}
            Here're all the choices: ${input["branches"]}
        """

        let system_prompt =  PREFIX + "\n"
        let user_prompt = SUFFIX
        let prompt_obj = JsonObject()
        prompt_obj.put("system", JsonString(system_prompt))
        prompt_obj.put("user", JsonString(user_prompt))
        return prompt_obj.toString()
    }
}

public class BranchAgent /*<: Runnable*/ {
    public var llm: OpenAI
    public var promptTemplate = BranchPromptTemplate()

    public init(llm: OpenAI) {
        this.llm = llm
    }

    public func invoke(input: Dict): ResponseMessage {
        let args = input["text"]
        let branches = input["branches"]
        let req = JsonObject()
        req.put("input", JsonString(args))
        req.put("branches", JsonString(branches))

        if (input.contains("messages")) {
            let msgs = getMessages(input["messages"])
            return invoke(req, msgs)
        }
        return invoke(req)
    }


    public func invoke(args: JsonObject, messages: ArrayList<Message>): ResponseMessage {
        println(args)
        let prompt: String = args.get("input").getOrThrow().asString().getValue()
        let branches: String = args.get("branches").getOrThrow().asString().getValue()
        var branch_agent_chain = LLMChain(llm, BranchPromptTemplate())

        let input = Dict()
        input["text"] = prompt
        input["branches"] = branches
 
        let input_string = promptTemplate.format(input)

        var response = branch_agent_chain.invoke(input_string, messages)
        return response
    }

    public func invoke(args: JsonObject): ResponseMessage {
        // println("HERE?")
        // println("HEREargs: ${args}")
        let prompt: String = args.get("input").getOrThrow().asString().getValue()
        let branches: String = args.get("branches").getOrThrow().asString().getValue()
        var branch_agent_chain = LLMChain(llm, BranchPromptTemplate())

        let input = Dict()
        input["text"] = prompt
        input["branches"] = branches

        let input_string = promptTemplate.format(input)

        var response = branch_agent_chain.invoke(input_string)
        return response
    }
}
