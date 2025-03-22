package canggraph.llmapi

import canggraph.util.{Tool, ResponseMessage, Message}

import std.collection.*

public enum LLMType {
    | OPEN_AI
    // | AZURE_OPEN_AI
    | OLLAMA
    | GPTGod
    | DeepSeek
}

let OPENAI_API_BASE = "http://api.xiaoai.plus/v1"
let OLLAMA_API_BASE = "http://localhost:11434/v1"
let GPTGod_API_BASE = "https://api.gptgod.online/v1"
let DeepSeek_API_BASE = "https://api.deepseek.com/v1"

let OPENAI_API_KEY = "sk-Y7BDSlT4EKjhVfPpA603Bb0cC549424b9d1734262f6fE6C0"
let OLLAMA_API_KEY = "sk-123"
let GPTGod_API_KEY = "sk-fs4JlNVh75fbxMrU1UsfXvIfVcEMVeqsDediEQk2pKPbns9F"
let DeepSeek_API_KEY = "sk-8dd8324c6ad344eea0be1316bdf720c4"

public func getLLMInstance(modelType: LLMType, model !: String = "gpt-4o-mini", chatUrl !: Option<String> = None): LargeModel {
    return match (modelType) {
        case OPEN_AI => OpenAI(model:model, base_url:OPENAI_API_BASE, api_key:OPENAI_API_KEY)
        // case AZURE_OPEN_AI => OpenAI(model:model, isAzureOpenAI:true)
        case OLLAMA => OpenAI(model:model, base_url:OLLAMA_API_BASE, api_key:OLLAMA_API_KEY)
        case GPTGod => OpenAI(model:model, base_url:GPTGod_API_BASE, api_key:GPTGod_API_KEY)
        case DeepSeek => OpenAI(model: model, base_url: DeepSeek_API_BASE, api_key: DeepSeek_API_KEY)
    }
}

public abstract class LargeModel {
    public func query(content: String, tools: Array<Tool>): ResponseMessage
    public func query(messages: Array<Message>, tools: Array<Tool>): ResponseMessage

    public func query(content: String): ResponseMessage
    public func query(messages: Array<Message>): ResponseMessage

    public func query(content: String, options: HashMap<String, Any>): ResponseMessage
    public func query(messages: Array<Message>, options: HashMap<String, Any>): ResponseMessage
}
