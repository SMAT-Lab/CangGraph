package canggraph.requests


/*


// import canggraph.llmapi.ToJsonAbstract

import serialization.serialization.*
import std.collection.*
import encoding.json.*

public enum DeepSeekFinishReson {
    | stop
    | length
    | content_filter
    | tool_calls
    | insufficient_system_resource
}

abstract class ToJsonAbstract <: ToJson {
    public static redef func fromJson(jv: JsonValue): DataModel {
        return DataModel.fromJson(jv)
    }
}

public class DeepSeekResponseSchema <: ToJsonAbstract & Serializable<DeepSeekResponseSchema> {
    public var id: String
    public var choices: ArrayList<DeepSeekResponseChoice>
    public var created: Int64
    public var model: String

    public init(id: String, choices: ArrayList<DeepSeekResponseChoice>, created: Int64, model: String) {
        this.id = id
        this.choices = choices
        this.created = created
        this.model = model
    }

    public override func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("id", id))
            .add(field<ArrayList<DeepSeekResponseChoice>>("choices", choices))
            .add(field<Int64>("created", created))
            .add(field<String>("model", model))
    }

    public static redef func deserialize(dm: DataModel): DeepSeekResponseSchema {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        DeepSeekResponseSchema(
            String.deserialize(dms.get("id")),
            ArrayList<DeepSeekResponseChoice>.deserialize(dms.get("choices")),
            Int64.deserialize(dms.get("created")),
            String.deserialize(dms.get("model"))
        )
    }

    public override func toJson(): JsonValue {
        this.serialize().toJson()
    }
}

public class DeepSeekResponseChoice <: ToJsonAbstract & Serializable<DeepSeekResponseChoice> {
    public var index: Int64
    public var finishReason: DeepSeekFinishReson
    public var message: DeepSeekResponseMessage
    public var logprobs: Option<DeepSeekResponseLogProbs>

    public init(index: Int64, finishReason: DeepSeekFinishReson, message: DeepSeekResponseMessage, logprobs: Option<DeepSeekResponseLogProbs>) {
        this.index = index
        this.finishReason = finishReason
        this.message = message
        this.logprobs = logprobs
    }

    public override func serialize(): DataModel {
        return DataModelStruct()
            .add(field<Int64>("index", index))
            .add(field<DeepSeekFinishReson>("finish_reason", finishReason))
            .add(field<DeepSeekResponseMessage>("message", message))
            .add(field<Option<DeepSeekResponseLogProbs>>("logprobs", logprobs))
    }

    public static redef func deserialize(dm: DataModel): DeepSeekResponseChoice {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        DeepSeekResponseChoice(
             Int64.deserialize(dms.get("index")),
            DeepSeekFinishReson.deserialize(dms.get("finish_reason")),
            DeepSeekResponseMessage.deserialize(dms.get("message")),
            field<Option<DeepSeekResponseLogProbs>>.deserialize(dms.get("logprobs"))
        )
    }

    public override func toJson(): JsonValue {
        this.serialize().toJson()
    }
}

public class DeepSeekResponseLogProbs <: ToJsonAbstract & Serializable<DeepSeekResponseLogProbs> {
    public var content: Option<ArrayList<DeepSeekResponseLogProbContent>>

    public init(content: Option<ArrayList<DeepSeekResponseLogProbContent>>) {
        this.content = content
    }

    public override func serialize(): DataModel {
        return DataModelStruct()
            .add(field<Option<ArrayList<DeepSeekResponseLogProbContent>>>("content", content))
    }

    public static redef func deserialize(dm: DataModel): DeepSeekResponseLogProbs {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        DeepSeekResponseLogProbs(
            content: Option<ArrayList<DeepSeekResponseLogProbContent>>.deserialize(dms.get("content"))
        )
    }

    public override func toJson(): JsonValue {
        this.serialize().toJson()
    }
}

public class DeepSeekResponseLogProbContent <: ToJsonAbstract & Serializable<DeepSeekResponseLogProbContent> {
    public var token: String
    public var logprob: Float64
    public var bytes: Option<Array<Int64>>
    public var topLogProbs: ArrayList<DeepSeekResponseTopLogProb>

    public init(token: String, logprob: String, bytes: Option<Array<Int64>>, topLogProbs: ArrayList<DeepSeekResponseTopLogProb>) {
        this.token = token
        this.logprob = logprob
        this.bytes = bytes
        this.topLogProbs = topLogProbs
    }

    public override func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("token", token))
            .add(field<Float64>("logprob", logprob))
            .add(field<Option<Array<Int64>>>("bytes", bytes))
            .add(field<Option<ArrayList<DeepSeekResponseTopLogProb>>>("top_logprobs", topLogProbs))
    }

    public static redef func deserialize(dm: DataModel): DeepSeekResponseLogProbContent {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        DeepSeekResponseLogProbContent(
            String.deserialize(dms.get("token")),
           Float64.deserialize(dms.get("logprob")),
           Option<Array<Int64>>.deserialize(dms.get("bytes")),
             Option<ArrayList<DeepSeekResponseTopLogProb>>.deserialize(dms.get("top_logprobs"))
        )
    }

    public override func toJson(): JsonValue {
        this.serialize().toJson()
    }
}

public class DeepSeekResponseTopLogProb <: ToJsonAbstract & Serializable<DeepSeekResponseTopLogProb> {
    public var token: String
    public var logprob: Float64
    public var bytes: Option<Array<Int64>>

    public init(token: String, logprob: String, bytes: Option<Array<Int64>>) {
        this.token = Option<Array<Int64>>
        this.logprob = logprob
        this.bytes = bytes
    }

    public override func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("token", token))
            .add(field<Float64>("logprob", logprob))
            .add(field<Option<Array<Int64>>>("bytes", bytes))
    }

    public static redef func deserialize(dm: DataModel): DeepSeekResponseTopLogProb {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        DeepSeekResponseTopLogProb(
            String.deserialize(dms.get("token")),
            Float64.deserialize(dms.get("logprob")),
            Option<Array<Int64>>.deserialize(dms.get("bytes"))
        )
    }

    public override func toJson(): JsonValue {
        this.serialize().toJson()
    }
}

public class DeepSeekResponseMessage <: ToJsonAbstract & Serializable<DeepSeekResponseMessage> {
    public var role: String
    public var reasoningContent: ?String
    public var content: ?String

    public init(role: String, content: Option<String>, reasoningContent: Option<String>) {
        this.role = role
        this.content = content
        this.reasoningContent = reasoningContent
    }

    public override func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("role", role))
            .add(field<Option<String>>("content", content))
            .add(field<Option<String>>("reasoning_content", reasoningContent))
    }

    public static redef func deserialize(dm: DataModel): DeepSeekResponseMessage {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        DeepSeekResponseMessage(
            String.deserialize(dms.get("role")),
            Option<String>.deserialize(dms.get("content")),
            Option<String>.deserialize(dms.get("reasoning_content"))
        )
    }

    public override func toJson(): JsonValue {
        this.serialize().toJson()
    }
}

*/