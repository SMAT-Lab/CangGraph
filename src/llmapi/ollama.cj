package llmapi
import requests.*
from net import http.*
from serialization import serialization.*
from encoding import json.*

public class Message <: Serializable<Message> {
    var role: String
    var content: String

    public init() {
        this.role = ""
        this.content = ""
    }

    public init(role: String, content: String) {
        this.role = role
        this.content = content
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("role", role))
        dms.add(field<String>("content", content))
        return dms
    }

    public static func deserialize(dm: DataModel): Message {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = Message()
        result.role = String.deserialize(dms.get("role"))
        result.content = String.deserialize(dms.get("content"))

        return result
    }
}

public class Ollama <: LargeModel {
    public var model_name: String = "arktsLLM"
    public var base_url: String = "http://127.0.0.1:13434/v1"
    public var api_key: String = "sk-123"
    public var messages: ArrayList<Message> = ArrayList<Message>()
    public var history: Bool = false
    public var stream: Bool = false

    public init() {
    }

    public init(model!: String = "arktsLLM", base_url!: String = "http://127.0.0.1:11434/v1", api_key!: String = "sk-123") {
        this.model_name = model
        this.base_url = base_url
        this.api_key = api_key
    }

    public func query(content: String, stop!: Bool = false): String {
        let url = "${base_url}/chat/completions"
        let header: HttpHeaders = HttpHeaders()
        header.add("Authorization", "Bearer " + api_key)
        header.add("Content-Type", "application/json")
        if (history) {
            var msg = Message("user", content)
            messages.append(msg)
        }
        else {
            var sys_msg = Message("system", "You are a helpful assistant!")
            messages.append(sys_msg)
            var msg = Message("user", content)
            messages.append(msg)
        }
        
        let body: DataModelStruct = DataModelStruct()
        body.add(field<String>("model", model_name))
        body.add(field<ArrayList<Message>>("messages", messages))

        let client = Requests()
        let response = client.post(url, header: header, body: body.toJson().toJsonString())
        return response
    }  

    public func query(messages: ArrayList<JsonValue>, stop!: Bool, tools!: ArrayList<JsonValue> , useTool!: Bool): String {
        let url = "${base_url}/chat/completions"
        let header: HttpHeaders = HttpHeaders()
        header.add("Authorization", "Bearer " + api_key)
        header.add("Content-Type", "application/json")

        let msgs: ArrayList<Message> = ArrayList<Message>()
        for (msg in messages) {
            let role = msg.asObject().get("role").getOrThrow().asString().getValue()
            let content = msg.asObject().get("content").getOrThrow().asString().getValue()
            msgs.append(Message(role, content))
        }
        
        let body: DataModelStruct = DataModelStruct()
        body.add(field<String>("model", model_name))
        body.add(field<ArrayList<Message>>("messages", msgs))

        let client = Requests()
        let response = client.post(url, header: header, body: body.toJson().toJsonString())
        return response
    } 

    public func query(messages: ArrayList<Message>, temperature!: Float32 = 0.0, max_token!: Int64 = 100): String {
        let url = "${base_url}/chat/completions"
        let header: HttpHeaders = HttpHeaders()
        header.add("Authorization", "Bearer " + api_key)
        header.add("Content-Type", "application/json")

        let body: DataModelStruct = DataModelStruct()
        body.add(field<String>("model", model_name))
        body.add(field<ArrayList<Message>>("messages", messages))
        body.add(field<Float32>("temperature", temperature))
        body.add(field<Int64>("max_token", max_token))

        let client = Requests()
        let response = client.post(url, header: header, body: body.toJson().toJsonString())
        return response
    }
    
    public func queryFunctionCall(content: String, tools: ArrayList<JsonValue>, useTool!: Bool): JsonObject {
        return JsonObject()
    }
}