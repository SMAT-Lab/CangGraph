package llmapi

import requests.*
import util.*

from net import http.*
from serialization import serialization.*
from encoding import json.*

public abstract class ToJsonAbstract <: ToJson {
    public static redef func fromJson(jv: JsonValue): DataModel {
        return DataModel.fromJson(jv)
    }
}

public class OpenAI <: LargeModel {
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

    public func call_llm(header: HttpHeaders, body: DataModelStruct): ResponseMessage {
        let url = "${base_url}/chat/completions"
        let client = Requests()
        // println(body.toJson())
        let response = client.post(url, header: header, body: body.toJson().toJsonString())
        // println(response)
        let obj: JsonObject = string2JsonObject(response)
        let msg = obj["choices"].asArray()[0].asObject()["message"].asObject()
        var content: String
        try {
            content = msg["content"].asString().getValue()
        }
        catch (e: Exception) {
            content = msg["content"].asNull().toString()
        }
        if (content == "null") {
            let functions = msg["tool_calls"].asArray()
            var response: ResponseMessage
            var called_tools = ArrayList<ToolCall>()
            for (i in 0..functions.size()) {
                let function_id = functions[i].asObject()["id"].asString().getValue()
                let function = functions[i].asObject()["function"].asObject()
                let function_name = function["name"].asString().getValue()
                let function_args = function["arguments"].toJsonString()
                let parse_args = parseString(function_args)
                let parse_args_obj = string2JsonObject(parse_args)

                var args = parse_args_obj.getFields()
                var tool_call_args = HashMap<String, String>()
                for ((k,v) in args) {
                    tool_call_args[k] = v.toString()
                }
                called_tools.append(ToolCall(function_name, tool_call_args, function_id))
            }
            response = ResponseMessage("assistant", "null", true, called_tools.toArray())
            return response
        }
        else {
            let content = msg["content"].asString()
            return ResponseMessage("assistant", content.getValue(), false, Array<ToolCall>())
        }
    }

    public func query(messages: Array<Message>, tools: Array<Tool>): ResponseMessage {
        let header: HttpHeaders = HttpHeaders()
        header.add("Authorization", "Bearer " + api_key)
        header.add("Content-Type", "application/json")
        
        let body: DataModelStruct = DataModelStruct()
        body.add(field<String>("model", model_name))
        body.add(field<Array<Message>>("messages", messages))
        body.add(field<Float64>("temperature", 0.0))
        body.add(field<Array<Tool>>("tools", tools))
        
        let content = HashMap<String, String>([("type", "string"), ("description", "The main content of the response.")])
        let schema = DataModelSeq()
        //let schema = DataModelStruct()
        schema.add(DataModelStruct().add(field<String>("type", "object"))
                                .add(field<HashMap<String, HashMap<String, String>>>("properties", HashMap<String, HashMap<String, String>>([("content", content)])))
                                .add(field<Array<String>>("required", ["content"]))
                                .add(field<Bool>("additionalProperties", false)))

        // let json_schema = DataModelStruct().add(field<String>("name", "simple_response"))
        //                         .add(field<Bool>("strict", true))
        //                         .add(field<ArrayList<Field>>("schema", schema.getItems()))
        // let responseFormat = [
        //                         "type": "json_schema",
        //                         "json_schema": [
        //                             "name": "simple_response",
        //                             "strict": true,
        //                             "schema": [
        //                                 "type": "object",
        //                                 "properties": [
        //                                     "content": [
        //                                         "type": "string",
        //                                         "description": "The main content of the response."
        //                                     ]
        //                                 ],
        //                                 "required": ["content"],
        //                                 "additionalProperties": false
        //                             ]
        //                         ]
        //                     ]

        if (!tools.isEmpty()) {
            body.add(field<String>("tool_choice", "auto"))
        }

        for(message in messages) {
            this.messages.append(message)
        }

        return call_llm(header, body)
    } 

    public func query(content: String, tools: Array<Tool>): ResponseMessage {
        let messages = ArrayList<Message>()
        let sys_msg = Message("system", "You are a helpful assistant.")
        let user_msg = Message("user", content)
        messages.append(sys_msg)
        messages.append(user_msg)
        return query(messages.toArray(), tools)
    }

    public func query(messages: Array<Message>, options: HashMap<String, Any>): ResponseMessage {
        var stop = false
        var tools = Array<Tool>()
        var temperature = 0.0

        if (options.contains("stop")) {
            stop = (options["stop"] as Bool).getOrThrow()
        }
        if (options.contains("tools")) {
            tools = (options["tools"] as Array<Tool>).getOrThrow()
        }
        if (options.contains("temperature")) {
            temperature = (options["temperature"] as Float64).getOrThrow()
        }

        let header: HttpHeaders = HttpHeaders()
        header.add("Authorization", "Bearer " + api_key)
        header.add("Content-Type", "application/json")

        let body: DataModelStruct = DataModelStruct()
        body.add(field<String>("model", model_name))
        body.add(field<Array<Message>>("messages", messages))
        body.add(field<Float64>("temperature", temperature))
        body.add(field<Array<Tool>>("tools", tools))

        return call_llm(header, body)
    }

    public func query(content: String, options: HashMap<String, Any>): ResponseMessage {
        let messages = ArrayList<Message>()
        let sys_msg = Message("system", "You are a helpful assistant.")
        let user_msg = Message("user", content)
        messages.append(sys_msg)
        messages.append(user_msg)
        return query(messages.toArray(), options)
    }

    public func query(messages: Array<Message>): ResponseMessage {
        return query(messages, HashMap<String, Any>())
    }

    public func query(content: String): ResponseMessage {
        let messages = ArrayList<Message>()
        let sys_msg = Message("system", "You are a helpful assistant.")
        let user_msg = Message("user", content)
        messages.append(sys_msg)
        messages.append(user_msg)
        return query(messages.toArray())
    }
}

public class LLMResponseFormat <: ToJsonAbstract & Serializable<LLMResponseFormat> {
    public var formatType: String
    public var jsonSchema: ArrayList<LLMResponseJsonSchema>

    public init(formatType!: String = "json_schema", jsonSchema!: ArrayList<LLMResponseJsonSchema> = ArrayList<LLMResponseJsonSchema>(LLMResponseJsonSchema())) {
        this.formatType = formatType
        this.jsonSchema = jsonSchema
    }

    public override func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("type", formatType))
            .add(field<ArrayList<LLMResponseJsonSchema>>("json_schema", jsonSchema))
    }

    public static redef func deserialize(dm: DataModel): LLMResponseFormat {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        LLMResponseFormat(
            formatType: String.deserialize(dms.get("type")),
            jsonSchema: ArrayList<LLMResponseJsonSchema>.deserialize(dms.get("json_schema"))
        )
    }

    public override func toJson(): JsonValue {
        this.serialize().toJson()
    }
}

public class LLMResponseJsonSchema <: ToJsonAbstract & Serializable<LLMResponseJsonSchema> {
    public var name: String
    public var strict: Bool
    public var schema: ArrayList<LLMResponseSchema>

    public init(name!: String = "simple_response", strict!: Bool = true, schema!: ArrayList<LLMResponseSchema> = ArrayList<LLMResponseSchema>(LLMResponseSchema())) {
        this.name = name
        this.strict = strict
        this.schema = schema
    }

    public override func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("name", name))
            .add(field<Bool>("strict", strict))
            .add(field<ArrayList<LLMResponseSchema>>("schema", schema))
    }

    public static redef func deserialize(dm: DataModel): LLMResponseJsonSchema {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        LLMResponseJsonSchema(
            name: String.deserialize(dms.get("name")),
            strict: Bool.deserialize(dms.get("strict")),
            schema: ArrayList<LLMResponseSchema>.deserialize(dms.get("schema"))
        )
    }

    public override func toJson(): JsonValue {
        this.serialize().toJson()
    }
}

public class LLMResponseSchema <: ToJsonAbstract & Serializable<LLMResponseSchema> {
    public var schemaType: String
    public var properties: ArrayList<LLMResponseProperties>
    public var required: ArrayList<String>
    public var additionalProperties: Bool

    public init(schemaType!: String = "object", properties!: ArrayList<LLMResponseProperties> = ArrayList<LLMResponseProperties>(LLMResponseProperties()), required!: ArrayList<String> = ArrayList<String>(["content"]), additionalProperties!: Bool = false) {
        this.schemaType = schemaType
        this.properties = properties
        this.required = required
        this.additionalProperties = additionalProperties
    }

    public override func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("type", schemaType))
            .add(field<ArrayList<LLMResponseProperties>>("properties", properties))
            .add(field<ArrayList<String>>("required", required))
            .add(field<Bool>("additionalProperties", additionalProperties))
    }

    public static redef func deserialize(dm: DataModel): LLMResponseSchema {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        LLMResponseSchema(
            schemaType: String.deserialize(dms.get("type")),
            properties: ArrayList<LLMResponseProperties>.deserialize(dms.get("properties")),
            required: ArrayList<String>.deserialize(dms.get("required")),
            additionalProperties: Bool.deserialize(dms.get("additionalProperties"))
        )
    }

    public override func toJson(): JsonValue {
        this.serialize().toJson()
    }
}

public class LLMResponseProperties <: ToJsonAbstract & Serializable<LLMResponseProperties> {
    public var content: ArrayList<LLMResponseContent>

    public init(content!: ArrayList<LLMResponseContent> = ArrayList<LLMResponseContent>(LLMResponseContent())) {
        this.content = content
    }

    public override func serialize(): DataModel {
        return DataModelStruct()
            .add(field<ArrayList<LLMResponseContent>>("content", content))
    }

    public static redef func deserialize(dm: DataModel): LLMResponseProperties {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        LLMResponseProperties(
            content: ArrayList<LLMResponseContent>.deserialize(dms.get("content"))
        )
    }

    public override func toJson(): JsonValue {
        this.serialize().toJson()
    }
}

public class LLMResponseContent <: ToJsonAbstract & Serializable<LLMResponseContent> {
    public var contentType: String
    public var description: String

    public init(contentType!: String = "string", description!: String = "The main content of the response.") {
        this.contentType = contentType
        this.description = description
    }

    public override func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("type", contentType))
            .add(field<String>("description", description))
    }

    public static redef func deserialize(dm: DataModel): LLMResponseContent {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        LLMResponseContent(
            contentType: String.deserialize(dms.get("type")),
            description: String.deserialize(dms.get("description"))
        )
    }

    public override func toJson(): JsonValue {
        this.serialize().toJson()
    }
}