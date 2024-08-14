package llmapi
import requests.*
from net import http.*
from serialization import serialization.*
from encoding import json.*
import util.*

public class GPTGod <: LargeModel {
    public var model_name: String = "arktsLLM"
    public var messages: ArrayList<Message> = ArrayList<Message>()
    public var history: Bool = false
    public var stream: Bool = false

    public var api_key: String = ""
    public var base_url: String = ""

    public init() {
        let envVars = envVars()
        let authKey = getAPIKey(envVars)
        var baseUrl = getOpenAIUrl(envVars)
        this.api_key = authKey
        this.base_url = baseUrl
    }

    public init(model!: String = "arktsLLM") {
        this.model_name = model
        let envVars = envVars()
        let authKey = getAPIKey(envVars)
        var baseUrl = getOpenAIUrl(envVars)
        this.api_key = authKey
        this.base_url = baseUrl
    }

    func getOpenAIUrl(envVars:HashMap<String, String>):String{
        let API_VERSION:String
        let ENDPOINT:String
        if (envVars.contains("OPENAI_API_BASE")) {
            return envVars["OPENAI_API_BASE"]
        }else {
            return "https://api.openai.com/v1"
        }
    }

    func getAPIKey(envVars:HashMap<String, String>){

        if (envVars.contains("OPENAI_API_KEY")) {
            return envVars["OPENAI_API_KEY"]
        }else{
            throw Exception(
                    "You didn't provide an API key. You need to provide your API key by set the environment variable 'OPENAI_API_KEY' ")
        }
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

    public func query(messages: Array<Message>, stop!: Bool, tools!: Array<Tool> , useTool!: Bool): JsonObject {
        let url = "${base_url}/chat/completions"
        let header: HttpHeaders = HttpHeaders()
        header.add("Authorization", "Bearer " + api_key)
        header.add("Content-Type", "application/json")
        
        let body: DataModelStruct = DataModelStruct()
        body.add(field<String>("model", model_name))
        body.add(field<Array<Message>>("messages", messages))
        if (stop){
            body.add(field<String>("stop", "Observation:"))
        }
        body.add(field<Float16>("temperature", 0.0))
        body.add(field<Array<Tool>>("tools", tools))
        
        if (useTool) {
            body.add(field<String>("tool_choice", "required"))
        } else {
            body.add(field<String>("tool_choice", "auto"))
        }

        let data: JsonObject = body.toJson().asObject()

        let client = Requests()
        let response = client.post(url, header: header, body: body.toJson().toJsonString())

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
            let function: JsonObject = msg["tool_calls"].asArray()[0].asObject()["function"].asObject()
            let function_name: JsonValue = function["name"]
            let function_args: String = function["arguments"].toJsonString()

            var parse_args = parseString(function_args) 
            var parse_args_obj = string2JsonObject(parse_args)       
            var res = JsonObject()
            res.put("function_name", function_name)
            res.put("function_args", parse_args_obj)
            res.put("tool_call", JsonBool(true))
            return res
        }
        else {
            let content = msg["content"].asString()
            var res = JsonObject()
            res.put("content", content)
            res.put("tool_call", JsonBool(false))
            return res
        }
    } 

    public func query(messages: ArrayList<JsonValue>, stop!: Bool, tools!: ArrayList<JsonValue> , useTool!: Bool): String {
        return ""
    }

    public func query(messages: ArrayList<Message>, temperature!: Float32 = 0.0, max_token!: Int64 = 4096): String {
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
        let obj: JsonObject = string2JsonObject(response)
        let msg = obj["choices"].asArray()[0].asObject()["message"].asObject()["content"].asString().getValue()

        return msg
    }
    
    public func queryFunctionCall(content: String, tools: ArrayList<JsonValue>, useTool!: Bool): JsonObject {
        return JsonObject()
    }
}