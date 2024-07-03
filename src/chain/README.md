测试代码






package chain

import llmapi.*

public class SimpleQAPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        return "You're a helpful assistant.\n\nQuestion: " + input["question"] + "\n\nAnswer: "
    }
}

public class SimpleQAChain <: LLMChain {
    public init() {
        super(ChatGPT(), SimpleQAPromptTemplate())
    }
}