package canggraph.chain

import canggraph.llmapi.*

public class SimpleQAPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        return "You're a helpful assistant.\n\nQuestion: " + input["question"] + "\n\nAnswer: "
    }
}

public class SimpleQAChain <: LLMChain {
    public init() {
        super(getLLMInstance(LLMType.OPEN_AI, model:"gpt-4o-mini"), SimpleQAPromptTemplate())
    }
}