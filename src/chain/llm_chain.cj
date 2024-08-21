package chain
import schema.*
import tool.*
from encoding import json.*
import llmapi.*


public open class LLMChain <: Chain {
    protected let llm: LargeModel
    protected let promptTemplate: PromptTemplate
    protected var tools: ArrayList<BaseTool> = ArrayList<BaseTool>()
    public var input: Dict = Dict()
    public var openai_tools: ArrayList<Tool> = ArrayList<Tool>()

    public init() {
        this.llm = getLLMInstance(LLMType.OPEN_AI, model:"gpt-4o-mini")
        this.promptTemplate = SelfDefinePromptTemplate()
        this.openai_tools = ArrayList<Tool>()
    }

    public init(llm: LargeModel, promptTemplate: PromptTemplate) {
        this.llm = llm
        this.promptTemplate = promptTemplate

        this.openai_tools = ArrayList<Tool>()
    }

    public init(llm: LargeModel, promptTemplate: PromptTemplate, tools: ArrayList<BaseTool>) {
        this.llm = llm
        this.promptTemplate = promptTemplate
        this.tools = tools
        
        for (tool in tools) {
            this.openai_tools.append(tool.tool)
        }
    }

    public func add_tool(tool: BaseTool) {
        this.tools.append(tool)
        this.openai_tools.append(tool.tool)
    }

    
    public func add_prompts(inputs: Dict) {
        for((k,v) in inputs) {
            this.input[k] = v
        }
    }

    public func add_prompt(key: String, value: String) {
        this.input[key] = value
    }

    public func invoke(dict: Dict): ResponseMessage {
        let input: String = dict["input"]
        this.add_prompt("user_message", input)
        let prompt: String = promptTemplate.format(this.input)
        return llm.query(prompt, openai_tools.toArray())
    }

    public func invoke(input: JsonObject): ResponseMessage {
        let messages = input["input"].toString()
        let tools = input["tools"]

        return invoke(messages)
    }

    public func invoke(message: String): ResponseMessage {
        let messages = ArrayList<Message>()
        let sys_msg = Message("system", "You are a helpful assistant.")
        let user_msg = Message("user", message)
        messages.append(sys_msg)
        messages.append(user_msg)

        return invoke(messages)
    }

    public func invoke(messages: ArrayList<Message>): ResponseMessage {
        let openai_tools = ArrayList<Tool>()
        for (tool in tools) {
            openai_tools.append(tool.tool)
        }
        let output = llm.query(messages.toArray(), openai_tools.toArray())
        return output
    }
}



