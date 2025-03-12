package canggraph

func graph() {
    let llm_OpenAI = (getLLMInstance(LLMType.OPEN_AI, model: "gpt-4o-mini") as OpenAI).getOrThrow()
	let tool_GetWeather = GetWeather()
	let agent1_create_openai_tools_agent = simple_prompt(llm_OpenAI)
	let node1 = Node("agent1", "agent", agent1_create_openai_tools_agent)

	let agent2_create_openai_tools_agent = simple_prompt(llm_OpenAI)
	let node2 = Node("agent2", "agent", agent2_create_openai_tools_agent)

	let graph = Graph()

	graph.addNode(node1)
	graph.addNode(node2)

    graph.setEntryPoint(node1)

    graph.addConditionalEdge(node1, node2)
    // graph.addEdge(node2, node1)

    graph.setExitPoint(node2)


	let input = Dict()
	input.put("text", "what is 321 plus 654?")

	graph.invoke(input)
	// return res.asObject().get("content").getOrThrow().asString().getValue()
}