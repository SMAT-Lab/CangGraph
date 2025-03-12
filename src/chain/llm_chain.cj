package canggraph.chain

import canggraph.schema.*
import canggraph.tool.*
import canggraph.llmapi.*

import encoding.json.*


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
        let input: String = dict["text"]
        this.input.putAll(dict)
        var msgs: ArrayList<Message> = ArrayList<Message>()
        if (this.input.contains("system_message")) {
            let system_message: String = this.input["system_message"]
            msgs.append(Message("system", system_message))
        }
        // 这里再进行一个promptFormat的处理
        let user_prompt: String = input
        msgs.append(Message("user", user_prompt))
        // this.add_prompt("user_message", input)
        // let prompt: String = promptTemplate.format(this.input)
        
        if (dict.contains("messages")) {
            let history = getMessages(dict["messages"])
            msgs.appendAll(history.slice(1..history.size))
            return llm.query(msgs.toArray(), openai_tools.toArray())
        }
        return llm.query(input, openai_tools.toArray())
    }

    public func invoke(dict: Dict, messages: ArrayList<Message>): ResponseMessage {
        let prompt: String = promptTemplate.format(dict)
        let msgs = ArrayList<Message>()
        msgs.append(Message("user", prompt))
        msgs.appendAll(messages)
        return llm.query(msgs.toArray(), openai_tools.toArray())
    }

    public func invoke(input: JsonObject): ResponseMessage {
        let messages = input["input"].toString()
        let tools = input["tools"]

        return invoke(messages)
    }

    public open func invoke(message: String): ResponseMessage {
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

    public func invoke(message: String, messages: ArrayList<Message>): ResponseMessage {
        let user_msg = Message("user", message)
        let msgs = ArrayList<Message>()
        msgs.append(user_msg)
        msgs.appendAll(messages)
        return invoke(msgs)
    }
}



