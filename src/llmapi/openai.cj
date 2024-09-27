package llmapi

import requests.*
import util.*

from net import http.*
from serialization import serialization.*
from encoding import json.*

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