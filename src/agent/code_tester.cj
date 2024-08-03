package agent
from encoding import json.*

import llmapi.*

public class CodeTesterPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            I will give you the code, you need to construct the test cases including input and output. 
            After that, you need to compare the output of the code with the output of the test cases.
            You have access to the following tools:${input["tool_names"]}
            
        """

        let FORMAT_INSTRUCTIONS = """
            Use the following format:
            Question: Construct the test cases including input and output for the code and compare the output of the code with the output of the test cases.
            Thought: you should always think about what to do
            Action: the action to take, should be one of ${input["tool_names"]}
            Observation: the result of the action
            ... (this Thought/Action/Observation can repeat N times)
            Thought: I now know the final answer
            Agent's Final Answer: Final answer
            """

        let SUFFIX = """
            Begin!
            Task: ${input["text"]}"""
        /* multi-role support */
        let system_prompt =  PREFIX + "\n" + FORMAT_INSTRUCTIONS + "\n"
        let user_prompt = SUFFIX
        let prompt_obj = JsonObject()
        prompt_obj.put("system", JsonString(system_prompt))
        prompt_obj.put("user", JsonString(user_prompt))
        return prompt_obj.toString()
    }
}

public class CodeTesterChain <: LLMChain {
    public init() {
        super(OpenAI(), CodeTesterPromptTemplate())
    }
}

public class CodeTesterAgent <: Role {
    public init(tools!: ArrayList<BaseTool> = ArrayList<BaseTool>(), agents!: ArrayList<Role> = ArrayList<Role>()) {
        super("Code_Tester", "When you have the code, you use this agent to construct the test case and test the code", CodeTesterChain(), MockOutputParser(), tools: tools, agents: agents)
        tools.append(pythonREPL())
        setArgs()
        println("CodeTesterAgent init done.")
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

        var res = CodeTesterChain().function_call(input, schema_tools)
        var ans: String = ""
        while (shouldContinue(res)){
            let function_name = res.get("function_name").getOrThrow().asString().getValue()
            let function_args = res.get("function_args").getOrThrow().asString().getValue()
            let value: JsonObject = JsonValue.fromStr(function_args).asObject()
            let action: AgentAction = AgentAction(function_name, value)
            let ob: String = executeAction(action)
            var msg: String = CodeTesterChain().generate_react(input)

            msg += "Observation: ${ob}\n"
            ans += msg
            input["text"] += msg
            res = CodeTesterChain().function_call(input, schema_tools)
        }

        ans += res.get("message").getOrThrow().asString().getValue()

        return ans
        
    }
}