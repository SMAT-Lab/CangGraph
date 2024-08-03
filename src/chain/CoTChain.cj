package chain
// 我想有一个chain，可以自定义SystemPrompt， 以及tools（或者function，其实是一样的），outputparser,然后可以接收输入，然后可以运行
public class CoTChain <: LLMChain & Runnable {
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

    public func invoke(dict: Dict): JsonObject {
        let input: String = dict["input"]
        this.add_prompt("user_message", input)
        let prompt: String = promptTemplate.format(this.input)
        let output = llm.queryFunctionCall(prompt, this.functions, useTool: true)
        let res = JsonObject()
        res.put("content", output)
        return res
    }

    public func run(args : Array<Any>) : Any {}

    public func invoke(args: JsonObject): String {
        "unimplemented"
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
