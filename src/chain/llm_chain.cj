package chain
import schema.BaseMemory
from encoding import json.*
import llmapi.*

public abstract class PromptTemplate {
    public open func format(input: Dict): String
}

public open class LLMChain <: Chain {
    protected let llm: LargeModel
    protected let promptTemplate: PromptTemplate

    public init(llm: LargeModel, promptTemplate: PromptTemplate) {
        this.llm = llm
        this.promptTemplate = promptTemplate
    }

    public override func generate(inputs: Collection<Dict>): Collection<Dict> {
        return collectArrayList(map({ input: Dict =>
            //println("input: ${input}")
            let prompt = promptTemplate.format(input)
            //println("prompt: ${prompt}")
            let output = llm.query(prompt, stop:false)
            return HashMap([("text", output)])
        })(inputs))
    }

    public func function_call(input: Dict, tools: ArrayList<JsonValue>): JsonObject {
        //println("prompt: ${prompt}")
        let output = llm.queryFunctionCall(promptTemplate.format(input), tools)
        return output
    }

    public func generate_react(input: Dict): String {
        //println("prompt: ${prompt}")
        let output = llm.query(promptTemplate.format(input), stop:true)
        return output
    }
}