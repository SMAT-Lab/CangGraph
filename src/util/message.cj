package canggraph.util

import serialization.serialization.*
import encoding.json.*
import std.collection.*

public class FunctionInfo <: Serializable<FunctionInfo> {
    public var name: String
    public var arguments: String

    public init(name: String, arguments: String) {
        this.name = name
        this.arguments = arguments
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("name", name))
        dms.add(field<String>("arguments", arguments))
        return dms
    }

    public static func deserialize(dm: DataModel): FunctionInfo {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = FunctionInfo(String.deserialize(dms.get("name")), String.deserialize(dms.get("arguments")))
        return result
    }
}

public class ToolCallMessage <: Serializable<ToolCallMessage>{
    public var id: String
    public var function: FunctionInfo
    public var function_type: String = "function"

    public init(id: String, function: FunctionInfo) {
        this.id = id
        this.function = function
    }

    public init(id: String, function: FunctionInfo, function_type: String) {
        this.id = id
        this.function = function
        this.function_type = function_type
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("id", id))
        dms.add(field<FunctionInfo>("function", function))
        dms.add(field<String>("type", function_type))
        return dms
    }

    public static func deserialize(dm: DataModel): ToolCallMessage {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = ToolCallMessage(String.deserialize(dms.get("id")), FunctionInfo.deserialize(dms.get("function")), String.deserialize(dms.get("type")))
        return result
    }

}

public class AgentCallMessage <: Serializable<AgentCallMessage> {
    public var id: String = "1"
    public var function: FunctionInfo
    public var function_type: String = "function"

    public init(id: String, function: FunctionInfo) {
        this.id = id
        this.function = function
    }

    public init(id: String, function: FunctionInfo, function_type: String) {
        this.id = id
        this.function = function
        this.function_type = function_type
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("id", id))
        dms.add(field<FunctionInfo>("function", function))
        dms.add(field<String>("type", function_type))
        return dms
    }

    public static func deserialize(dm: DataModel): AgentCallMessage {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = AgentCallMessage(String.deserialize(dms.get("id")), FunctionInfo.deserialize(dms.get("function")), String.deserialize(dms.get("type")))
        return result
    }
}

public class Message <: Serializable<Message> {
    var role: String
    var content: String
    var tool_call_id: Option<String> = None
    var tool_calls: ArrayList<ToolCallMessage> = ArrayList<ToolCallMessage>()

    public init() {
        this.role = ""
        this.content = ""
    }

    public init(role: String) {
        this.role = role
        this.content = ""
    }

    public init(role: String, content: String) {
        this.role = role
        this.content = content
    }

    public func set_tool_call_id(id: String) {
        this.tool_call_id = Some(id)
    }

    public func add_tool_calls(tool_call: ToolCallMessage) {
        this.tool_calls.append(tool_call)
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("role", role))
        dms.add(field<String>("content", content))
        match(tool_call_id) {
            case Some(id) => 
                dms.add(field<String>("tool_call_id", id))
            case None =>
                dms
        }
        match(tool_calls.size) {
            case 0 =>
                dms
            case _ =>
                dms.add(field<ArrayList<ToolCallMessage>>("tool_calls", tool_calls))
        }
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
        result.tool_call_id = String.deserialize(dms.get("tool_call_id"))
        result.tool_calls = ArrayList<ToolCallMessage>.deserialize(dms.get("tool_calls"))

        return result
    }

    public func toString() {
        return """
            Role: ${role}
            Content: ${content}
        """
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

    public func getContent(): String {
        return this.content
    }

    public func getToolCalls(): String {
        // for (call in tool_calls) {
        //     println(call.toString())
        // }
        return this.tool_calls[0].toString()
    }
}

public func getMessages(message_string: String): ArrayList<Message> {
    let messages = JsonValue.fromStr(message_string).asArray()
    let msgs = ArrayList<Message>()

    for (msg in messages.getItems()) {
        let message: JsonObject = msg.asObject()
        let role = message.get("role").getOrThrow().asString().getValue()
        let content = message.get("content").getOrThrow().asString().getValue()
        let message1: Message = Message(role, content)
        msgs.append(message1)
    }
    // let messages: ArrayList<Message> = input["messages"]
    return msgs
}