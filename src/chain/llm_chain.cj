package chain
import schema.*
import tool.*
from encoding import json.*
import llmapi.*


public open class LLMChain <: Chain {
    protected let llm: LargeModel
    protected let promptTemplate: PromptTemplate

    public init() {
        this.llm = OpenAI()
        this.promptTemplate = SelfDefinePromptTemplate()
    }

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

// 我想有一个chain，可以自定义SystemPrompt， 以及tools（或者function，其实是一样的），outputparser,然后可以接收输入，然后可以运行
public class CoTChain <: LLMChain {
    public var tools: ArrayList<BaseTool>
    public var functions: ArrayList<JsonValue> = ArrayList<JsonValue>()
    public var input: Dict = Dict()

    public init(llm: LargeModel, promptTemplate!: SelfDefinePromptTemplate = SelfDefinePromptTemplate(), tools!: ArrayList<BaseTool> = ArrayList<BaseTool>()) {
        super(llm, promptTemplate)
        this.tools = tools

        this.add_tool_function()
    }

    public func add_tool_function() {
        for(tool in this.tools) {
            functions.append(tool.args_schema.getOrThrow())
        }
    }

    public func add_prompts(inputs: Dict) {
        for((k,v) in inputs) {
            this.input[k] = v
        }
    }

    public func add_prompt(key: String, value: String) {
        this.input[key] = value
    }

    public func avoke(input: String): JsonObject {
        this.add_prompt("user_message", input)
        let prompt: String = promptTemplate.format(this.input)
        let output = llm.queryFunctionCall(prompt, this.functions)
        return output
    }

    public func bind_function(function: JsonValue) {
        this.functions.append(function)
    }

    public func bind_function(functions: ArrayList<JsonValue>) {
        for(f in functions) {
            this.functions.append(f)
        }
    }
}


