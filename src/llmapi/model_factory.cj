package llmapi
from std import collection.*
public enum LLMType {
    | OPEN_AI
    | AZURE_OPEN_AI
}

public func getLLMInstance(modelType: LLMType, model !: String = "gpt-4o") {
    return match (modelType) {
        case OPEN_AI => OpenAI(model:model)
        case AZURE_OPEN_AI => OpenAI(model:model, isAzureOpenAI:true)
    }
}

public abstract class LargeModel {
    public open func query(content: String, stop!: Bool): String
    public open func queryFunctionCall(content: String, tools: ArrayList<JsonValue>): JsonObject
}
