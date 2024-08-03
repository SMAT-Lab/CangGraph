package agent
from encoding import json.*
from std import unicode.*
import llmapi.*

public class MockOutputParser <: OutputParser<AgentOutput> {
    public override func parse(output: Dict): AgentOutput {
        return Finish(output["text"])
    }
}

public class ReActAgentOutputParser <: OutputParser<AgentOutput> {
    public override func parse(output: Dict): AgentOutput {
        let text: String = output["text"]
        let partial = text.split("Question:")[1].trim()
        if (partial.contains("Final Answer:")) {
            return Finish(partial.split("Final Answer:")[1].trim())
        } else {
            let lines = partial.split("\n")
            var action = ""
            var actionInput = ""
            for(line in lines) {
                if (line.contains("Action:")) {
                    action = line.split("Action:")[1].trim()
                }
                if (line.contains("Action Input:")) {
                    actionInput = line.split("Action Input:")[1].trim()
                }
            }
            return Action(AgentAction(action, actionInput))
        }
    }
}

public class SimpleReActPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            Answer the following questions as best you can. You have access to the following tools:"""

        let FORMAT_INSTRUCTIONS = """
            If you don't know the final answer, your output must obey the following format:  
                Question: the input question you must answer
                Thought: you should always think about what to do
                Action: the action to take, should be one of ${input["tool_names"]}
                Action Input: the input to the action
            Else, if you know the final answer, your output must obey the following format:
                Question: the input question you must answer
                Thought: I now know the final answer
                Final Answer: the final answer to the original input question
            """

        let SUFFIX = """
            Begin!
            Question: ${input["text"]}"""
        /* multi-role support */
        let system_prompt =  PREFIX + "\n" + FORMAT_INSTRUCTIONS + "\n"
        let user_prompt = SUFFIX
        let prompt_obj = JsonObject()
        prompt_obj.put("user", JsonString(user_prompt))
        prompt_obj.put("system", JsonString(system_prompt))
        return prompt_obj.toString()
    }
}

public class GraphAgentPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            Answer the following questions as best you can. 
            Choose the best node according the final result to take next step. 
            Here are all nodes choices: ${input["choices"]}
            You have access to the following tools:
            """

        let FORMAT_INSTRUCTIONS = """
            If you don't know the final answer, your output must obey the following format:  
                Question: the input question you must answer
                Thought: you should always think about what to do
                Action: the action to take, should be one of ${input["tool_names"]}
                Action Input: the input to the action
            Else, if you know the final answer, your output must obey the following format:
                Question: the input question you must answer
                Thought: I now know the final answer
                Final Answer: the final answer to the original input question.
                Next Node: the best node among given choices to take next step.
            """

        let SUFFIX = """
            Begin!
            Question: ${input["text"]}"""
        /* multi-role support */
        let system_prompt =  PREFIX + "\n" + FORMAT_INSTRUCTIONS + "\n"
        let user_prompt = SUFFIX
        let prompt_obj = JsonObject()
        prompt_obj.put("user", JsonString(user_prompt))
        prompt_obj.put("system", JsonString(system_prompt))
        return prompt_obj.toString()
    }
}

public class SimpleReActChain <: LLMChain {
    public init() {
        super(OpenAI(), SimpleReActPromptTemplate())
    }
}

public class GraphAgentChain <: LLMChain {
    public init() {
        super(OpenAI(), GraphAgentPromptTemplate())
    }
}

public class SimpleReActAgent <: Agent {
    public init(tools: ArrayList<BaseTool>) {
        super(SimpleReActChain(), ReActAgentOutputParser(), tools)
        println("ReActAgent init done.")
    }
    public init(input: String, edges: HashMap<String, HashMap<String, String>>, tools: ArrayList<BaseTool>) {
        super(GraphAgentChain(), ReActAgentOutputParser(), tools)
        println("GraphAgent init done.")
    }
    public override func constructAgentScratchpad(input: Dict, intermediateSteps: ArrayList<StepResult>, stepCount: Int64): Dict {
        println("ReActAgent: takeNextStep(${stepCount})")
        let scratchpad = Dict()
        scratchpad["text"] = ""
        let toolNamesList  = collectArrayList(map({tool:BaseTool => tool.name})(tools))
        var toolNames = ""
        for (toolName in toolNamesList) {
            toolNames += toolName + ", "
        }
        scratchpad["tool_names"] = toolNames
        scratchpad["step_count"] = stepCount.toString()
        println("intermediateSteps: ${intermediateSteps.size}")
        for (stepResult in intermediateSteps) {
            let output = stepResult.output
            let log = stepResult.log
            scratchpad["text"] += "Step: "; scratchpad["text"] += stepCount.toString(); scratchpad["text"] += "\n"
            scratchpad["text"] += log + "\n"
            match (output) {
                case Finish(text) => 
                    scratchpad["text"] += "Result: "; scratchpad["text"] += text
                case Action(action) => scratchpad["text"] += "Observation: "; scratchpad["text"] += action.observation ?? "No observation" ; scratchpad["text"] += "\n"
                case Actions(actions) => 
                    for (action in actions) {
                        scratchpad["text"] += "Observation: "
                        scratchpad["text"] += action.observation ?? "No observation" ; scratchpad["text"] += "\n"
                    }
            }
        }
        scratchpad["text"] += input["text"]
        scratchpad
    }

}