package multi

import llmapi.*
import schema.*
import chain.*
import tool.*
import agent.*
import util.*

from std import unicode.*, collection.*
from encoding import json.*
from serialization import serialization.*

public class PlannerPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            Answer the following questions as best you can. You have command on the following agents"""

        let FORMAT_INSTRUCTIONS = """
            
            ${input["agent_names"]}

            The descriptions of the agents are follow:
            ${input["agent_with_descriptions"]}

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

public class PlannerChain <: LLMChain {
    public init(tools: ArrayList<BaseTool>) {
        super(getLLMInstance(LLMType.OPEN_AI, model:"gpt-4o-mini"), PlannerPromptTemplate(), tools)
    }
}

public class Planner <: Agent & ActionExecutor {
    public var agents: ArrayList<Agent> = ArrayList<Agent>()
    public init(agents: ArrayList<Agent>, tools: ArrayList<BaseTool>) {
        super(PlannerChain(tools), tools)
        this.agents.appendAll(agents)
        println("Planner init done.")
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
        let messages = ArrayList<Message>()
        let input = Dict()
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

        let agentNamesList = collectArrayList(map({agent:Agent => agent.agentName})(agents))
        var agentNames = ""
        for (agentName in agentNamesList) {
            agentNames += agentName + ", "
        }
        input["agent_names"] = agentNames

        let agentDescriptionsList = collectArrayList(map({agent:Agent => agent.agentDescription})(agents))
        var agentDescriptions = ""
        for (agentDescription in agentDescriptionsList) {
            agentDescriptions += agentDescription + ", "
        }
        input["agent_descriptions"] = agentDescriptions

        var res: ResponseMessage = agentChain.invoke(input)
        while (shouldContinue(res)) {
            let agentCalls = (res.serialize().toJson() as JsonObject).getOrThrow().get("agent_calls").getOrThrow().asArray()
            for (i in 0..agentCalls.size()) {
                let agentCall = agentCalls[i].asObject()
                let agentName: String = agentCall.get("name").getOrThrow().asString().getValue()
            }
            
            println(messages.serialize().toJson())
            res = agentChain.invoke(input, messages)
        }
        return res
    }

    public func executeAction(action: AgentAction): String { // "tool" under consideration
        for (agent in tools) {
            if (agent.name == action.toolName) {
                let res: ResponseMessage = agent.invoke(action.toolArgs)
                return res.serialize().toJson().asObject().get("content").getOrThrow().asString().getValue()
            }
        }
        return "Unknown agent: ${action.toolName}"
    }
}