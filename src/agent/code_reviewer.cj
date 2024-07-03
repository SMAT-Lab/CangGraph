package agent
from encoding import json.*

import llmapi.*

public class CodeReviewerPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            I will give you the original code. You should review the code and debug the code, and improve the code quality as best you can. 
            You must output the code after debugging and improving the quality.
            !!! You use the FileReader tool to read the code before the actions, and the FileWriter tool to write the code after the actions.
            !!! First, read the content of file, you should get the filename according to the messages above from the observation, don't make it by yourself. Second, improve the code quality. Last, save the code.
            You have access to the following tools: ${input["tool_names"]}
        """

        let FORMAT_INSTRUCTIONS = """
            Use the following format:
            Question: Debug the code, and improve the code quality
            Thought: You should always think about what to do. 
            Action: the action to take
            Observation: the result of the action
            ... (this Thought/Action/Observation can repeat N times)
            Thought: I now rewrite the code to debug and improve the quality
            Agent's Final Answer: the code after debugging and improving the quality.
            """

        let SUFFIX = """
            Begin!
            The original task: ${input["text"]}
            I should read the file first, then I will start to debug and improve the quality of the code. And after that, I should use tool to save it.
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

public class CodeReviewerChain <: LLMChain {
    public init() {
        super(OpenAI(), CodeReviewerPromptTemplate())
    }
}

public class CodeReviewerAgent <: Role {
    public init(tools!: ArrayList<BaseTool> = ArrayList<BaseTool>([FileSaver(), FileReader()]), agents!: ArrayList<Role> = ArrayList<Role>()) {
        super("Code_Reviewer", "After having a code, you can use this agent to review the code in order to improve the quality of the code", CodeReviewerChain(), MockOutputParser(), tools: tools, agents: agents)
        setArgs()
        println("CodeReviewerAgent init done.")
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

        var res = CodeReviewerChain().function_call(input, schema_tools)
        var read = false

        var ans: String = ""
        while (shouldContinue(res)){
            let function_name = res.get("function_name").getOrThrow().asString().getValue()
            let function_args = res.get("function_args").getOrThrow().asString().getValue()
            let value: JsonObject = JsonValue.fromStr(function_args).asObject()
            let action: AgentAction = AgentAction(function_name, value)
            let ob: String = executeAction(action)
            var msg: String = CodeReviewerChain().generate_react(input)

            if (function_name == "file_reader" && !read) {
                read = true
                msg += "\nObservation: I have read the file. The content is: \n${ob}\nThen I will start to debug and improve the quality of the code. And after that, I should use tool to save it.\n" 
            }
            else {
                msg += "\nObservation: \n${ob}\nThen I should save it to a file.\n"   
            }
            ans += msg
            input["text"] += msg

            res = CodeReviewerChain().function_call(input, schema_tools)
        }
        ans += res.get("message").getOrThrow().asString().getValue()
        // let msg: String = CodeReviewerChain().generate_react(input)
        let lines = ans.split("\n")
        var ret = ""
        for (line in lines) {
            if (line.startsWith("Agent's Answer:")) {
                ret = line.split(":")[1].trim()
            }
        }
        return ret
        
    }
}