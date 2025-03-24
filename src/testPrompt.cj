package canggraph

import canggraph.agent.*
import canggraph.graph.*
import canggraph.llmapi.*
import canggraph.tool.*

import std.collection.*

func promptgraph() {
    let llm = (getLLMInstance(LLMType.DeepSeek, model: "deepseek-chat") as OpenAI).getOrThrow()
	let agent_simple_prompt = simple_prompt(llm, selfDifinedPrompt: selfDifinedPrompts["assistant"])
	let node1 = Node("agent1", "agent", agent_simple_prompt)
    let calculater_prompt = simple_prompt(llm, selfDifinedPrompt: selfDifinedPrompts["calculater"])
    let node2 = Node("calculater", "agent", calculater_prompt)
    // let tool_GetWeather = GetWeather()
    // let agent1_create_openai_tools_agent = create_openai_tools_agent(llm_OpenAI, ArrayList<BaseTool>([GetWeather()]))
    // let node3 = Node("weatherGetter", "agent", agent1_create_openai_tools_agent)

	let graph = Graph()

	graph.addNode(node1)
    graph.addNode(node2)
    // graph.addNode(node3)

    graph.setEntryPoint(node1)

    // BranchEdge(node1, "calculate or weather", HashMap<String, Node>(("calculate", node2), ("weather", node3)))


    // graph.addEdge(node2, node1)

    graph.setExitPoint(node2)


	let input = HashMap<String, String>()
	input.put("text", "Why `while (true)` is not suggested?")

	graph.invoke(input)
	// return res.asObject().get("content").getOrThrow().asString().getValue()
}