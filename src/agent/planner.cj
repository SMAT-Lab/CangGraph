package agent
from encoding import json.*

import llmapi.*

public class PlannerPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            You are a planner who have multiple agent to use to finish the task.
            You have the following agents to use: ${input["agent_names"]}.
            !!! You mustn't use the same agents in every two steps. 
            You should use the agent to take next step if there is agent to be used.
            The description of the agents are as follows:
            ${input["agent_descriptions"]}
            Your output should be formatted as follows:
        """

        let FORMAT_INSTRUCTIONS = """
            Question: The question
            Thought: you should always think about what to do. 
            Action: the agent to take, must be one of ${input["agent_names"]}.
            Observation: the observation of the action, the output of the agent.
            ... (this Thought/Action/Observation can repeat N times)
            Thought: I now know the final answer
            Final Answer: the final answer to the original input question
        """

        let SUFFIX = """
            Begin!
            The task: ${input["text"]}
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

public class PlannerChain <: LLMChain {
    public init() {
        super(OpenAI(), PlannerPromptTemplate())
    }
}

// Planner主要是用来挑选下一步的Agent角色
public class PlannerAgent <: Role {
    public init(tools!: ArrayList<BaseTool> = ArrayList<BaseTool>(), agents!: ArrayList<Role> = ArrayList<Role>()) {
        super("Planner", "The manager of multi agent to decide which agent to use", PlannerChain(), MockOutputParser(), tools: tools, agents: agents)
        println("PlannerAgent init done.")
    }

    public func generate(input: Dict): String{
        let output = super.predict(input["text"])["text"]
        output
    }

    public func shouldContinue(res: JsonObject): Bool {
        match (res.get("message")) {
            case None => return true
            case Some(_) => return false
        }
    }

    public func generate(text: String): String {
        var schema_tools: ArrayList<JsonValue> = ArrayList()
        for (agent in agents) {
            schema_tools.append(agent.args_schema)
        }
        let input = Dict()
        input["text"] = text
        let toolNamesList  = collectArrayList(map({tool:BaseTool => tool.name})(tools))
        var toolNames = ""
        for (toolName in toolNamesList) {
            toolNames += toolName + ", "
        }
        input["tool_names"] = toolNames

        let agentNamesList = collectArrayList(map({agent:Role => agent.role})(agents))
        var agentNames = ""
        for (agentName in agentNamesList) {
            agentNames += agentName + ", "
        }

        let agentDescriptionsList = collectArrayList(map({agent:Role => agent.description})(agents))
        var agentsWithDescriptions = ""
        for (i in 0..agentDescriptionsList.size) {
            agentsWithDescriptions += agentNamesList[i] + "( " + agentDescriptionsList[i] + "), "
        }
        input["agent_names"] = agentNames
        input["agent_descriptions"] = agentsWithDescriptions

        let toolDescriptionsList  = collectArrayList(map({tool:BaseTool => tool.description})(tools))
        var toolWithDescriptions = ""
        for (i in 0..toolDescriptionsList.size) {
            toolWithDescriptions += toolNamesList[i] + "(" + toolDescriptionsList[i] + "), "
        }
        input["tool_with_descriptions"] = toolWithDescriptions

        var res = PlannerChain().function_call(input, schema_tools)
        var ans: String = ""
        while (shouldContinue(res)){
            let agent_name = res.get("function_name").getOrThrow().asString().getValue()
            let function_args = res.get("function_args").getOrThrow().asString().getValue()
            let value: JsonObject = JsonValue.fromStr(function_args).asObject()
            let query: String = value.get("query").getOrThrow().asString().getValue()

            println("===========\nagent_name: ${agent_name}\nquery:${query}\n===========")
            let action: AgentAction = AgentAction("", agent_name, query)
            var ob: String = executeRole(action)
            ob = "\nObservation:" + ob + "\n"
            var msg: String = PlannerChain().generate_react(input)
            msg += ob
            ans += msg
            input["text"] += msg
            res = PlannerChain().function_call(input, schema_tools)
        }

        ans += res.get("message").getOrThrow().asString().getValue()

        return ans
        
    }

    public func executeRole(role: AgentAction): String {
        println("Executing role: ${role.agentName.getOrThrow()}")
        for (agent in agents) {
            if (agent.role == role.agentName.getOrThrow()) {
                return agent.generate(role.input)
            }
        }
        // let output = planner.predict()
        return "Unknown agent: ${role.agentName.getOrThrow()}"
    }
    
}