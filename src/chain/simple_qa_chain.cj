package canggraph.chain

import canggraph.llmapi.*
import canggraph.schema.*

public class SimpleQAPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        return "You're a helpful assistant.\n\nQuestion: " + input["question"] + "\n\nAnswer: "
    }
}

public class SimpleQAChain <: LLMChain {
    public init() {
        super(getLLMInstance(LLMType.DeepSeek, model:"deepseek-chat"), SimpleQAPromptTemplate())
    }
}