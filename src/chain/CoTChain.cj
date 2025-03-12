package canggraph.chain

import canggraph.util.*
// 我想有一个chain，可以自定义SystemPrompt， 以及tools（或者function，其实是一样的），outputparser,然后可以接收输入，然后可以运行
public class CoTChain <: LLMChain & Runnable {

    public init(llm: LargeModel, promptTemplate!: SelfDefinePromptTemplate = SelfDefinePromptTemplate(), tools!: ArrayList<BaseTool> = ArrayList<BaseTool>()) {
        super(llm, promptTemplate, tools)
    }

    public func bind_function(function: BaseFunction ) {
        this.openai_tools.append(function.get_function_tool())
    }

    public func bind_function(functions: ArrayList<BaseFunction>) {
        for(f in functions) {
            this.openai_tools.append(f.get_function_tool())
        }
    }

    public func get_tools(): ArrayList<BaseTool> {
        return this.tools
    }
}
