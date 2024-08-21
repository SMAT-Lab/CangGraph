package util
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


public class ResponseMessage <: Serializable<ResponseMessage> {
    var role: String
    var content: String
    var tool_call: Bool
    var tool_calls: Array<ToolCall>

    public init() {
        this.role = "assistant"
        this.content = ""
        this.tool_call = false
        this.tool_calls = Array<ToolCall>()
    }

    public init(role: String, content: String, tool_call: Bool, tool_calls: Array<ToolCall>) {
        this.role = role
        this.content = content
        this.tool_call = tool_call
        this.tool_calls = tool_calls
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("role", role))
        dms.add(field<String>("content", content))
        dms.add(field<Bool>("tool_call", tool_call))
        dms.add(field<Array<ToolCall>>("tool_calls", tool_calls))
        return dms
    }

    public static func deserialize(dm: DataModel): ResponseMessage {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = ResponseMessage()
        result.role = String.deserialize(dms.get("role"))
        result.content = String.deserialize(dms.get("content"))
        result.tool_call = Bool.deserialize(dms.get("tool_call"))
        result.tool_calls = Array<ToolCall>.deserialize(dms.get("tool_calls"))

        return result
    }
    
}