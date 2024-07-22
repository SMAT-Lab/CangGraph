/*
   Ref： https://platform.openai.com/docs/api-reference/images/create
 */
package llmapi

from std import os.envVars
from std import collection.*
from encoding import json.*
from std import fs.File
import tool.*

foreign func send_llm_request(auth_header: CString, url: CString, response: CPointer<UInt8>, buffer_size: UIntNative,  data_content: CString): CString
foreign func set_stream(cb:CFunc< (CString) -> Int32 >):Unit
foreign func unset_stream():Unit

// @C
// func myCallback(s: CString): Int32 {
//     // println("${s}")
//     let str = s.toString()
//     if (str == "[Done]") {
//         return 1
//     }
//     let start_idx = str.indexOf("{").getOrThrow()
//     let rep = JsonValue.fromStr(str[start_idx..]).asObject()
//     let choices = rep.get("choices").getOrThrow().asArray()
//     var finish_reason=""
//     for(item in choices.getItems()){
//         let item_obj = (item as JsonObject).getOrThrow()
//         println(item_obj)
//         finish_reason = item_obj.get("finish_reason").getOrThrow().toString()
//         // println(finish_reason)
//         let delta = (item_obj.get("delta").getOrThrow() as JsonObject).getOrThrow()
//         // println(delta)
//         let content = delta.get("content").getOrThrow().asString().getValue()
//         println("${content}")
//     }
//     if(finish_reason == "null") {
//         return 0
//     }
//     return 1
// }

public class OpenAI <: LargeModel {
    private var authHeader: CString = unsafe { LibC.mallocCString("Content-Type: application/json") }
    private var chatUrl: CString = unsafe { LibC.mallocCString("https://api.openai.com/v1/chat/completions") }
    private var embeddingUrl: CString = unsafe { LibC.mallocCString("https://api.openai.com/v1/embeddings") }
    // private var chatUrl: CString = unsafe { LibC.mallocCString("https://api.xty.app/v1/chat/completions") }
    // private var embeddingUrl: CString = unsafe { LibC.mallocCString("https://api.xty.app/v1/embeddings") }
    private let history_messages = ArrayList<JsonValue>()
    public var queryWithHistoryMsg = false
    public var model = "gpt-4o"
    public var queryWithStreamMode = false
    private let bufferSize: UIntNative = 1024000
    private let response: CPointer<UInt8> = unsafe{ LibC.malloc<UInt8>(count: Int64(bufferSize))}
    public init(model!:String="gpt-4o", isAzureOpenAI!:Bool=false) {
        this.model = model
        let envVars = envVars()
        let authKey = getAPIKey(envVars)
        let baseUrl = getOpenAIUrl(envVars)
        let auHeader:HashMap<String, String> = HashMap<String, String>()
        // auHeader.put("Content-Type", "application/json")
        if (isAzureOpenAI) {
            unsafe{
                LibC.free(this.chatUrl)
                LibC.free(this.embeddingUrl)
            }
            let urls:(String, String) = getAzureOpenAIUrl(envVars)
            this.chatUrl = unsafe { LibC.mallocCString(urls[0]) }
            this.embeddingUrl = unsafe { LibC.mallocCString(urls[1]) }
            auHeader.put("api-key", authKey)
        }else {
            this.chatUrl = unsafe { LibC.mallocCString("${baseUrl}/chat/completions") }
            this.embeddingUrl = unsafe { LibC.mallocCString("${baseUrl}/embeddings") }
            auHeader.put("Authorization", "Bearer "+authKey)
        }
        var auStr: String = String()
        for((key,value) in auHeader){
            auStr = auStr + key + ": " + value
        }
        this.authHeader = unsafe { LibC.mallocCString(auStr) }
        println("OpenAI init done.")
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

    func getAzureOpenAIUrl(envVars:HashMap<String, String>):(String,String){
        let API_VERSION:String
        let ENDPOINT:String
        let DEPLOYMENT_NAME_CHAT:String
        let DEPLOYMENT_NAME_EMBED:String
        if (envVars.contains("OPENAI_API_VERSION")) {
            API_VERSION = envVars["OPENAI_API_VERSION"]
        }else {
          throw Exception("You didn't provide 'OPENAI_API_VERSION'. You need to provide your API key by set the environment variable 'OPENAI_API_VERSION'")
        }
        if (envVars.contains("ENDPOINT")) {
            ENDPOINT  = envVars["ENDPOINT"]
        }else{
            throw Exception( "You didn't provide 'ENDPOINT'. You need to provide your API key by set the environment variable 'ENDPOINT'")
        }
        if (envVars.contains("DEPLOYMENT_NAME_CHAT")) {
            DEPLOYMENT_NAME_CHAT  = envVars["DEPLOYMENT_NAME_CHAT"]
        }else{
            throw Exception("You didn't provide 'DEPLOYMENT_NAME_CHAT'. You need to provide your API key by set the environment variable 'DEPLOYMENT_NAME_CHAT'")
        }
        if (envVars.contains("DEPLOYMENT_NAME_EMBEDDINGS")) {
            DEPLOYMENT_NAME_EMBED  = envVars["DEPLOYMENT_NAME_EMBEDDINGS"]
        }else{
            throw Exception("You didn't provide 'DEPLOYMENT_NAME_EMBEDDINGS'. You need to provide your API key by set the environment variable 'DEPLOYMENT_NAME_EMBEDDINGS'")
        }
        let chatUrl = "${ENDPOINT}/openai/deployments/${DEPLOYMENT_NAME_CHAT}/chat/completions?api-version=${API_VERSION}"
        let embeddingUrl = "${ENDPOINT}/openai/deployments/${DEPLOYMENT_NAME_EMBED}/embeddings?api-version=${API_VERSION}"
        return (chatUrl,embeddingUrl)
    }

    // todo: enable multiple messages, e.g., 
    // [{"role": "system", "content": "You are a helpful assistant."}, {"role": "user", "content": "Hello!"}] 
    func creatChatQueryPostData(content: String, stop!: Bool=false) {
        let messages:ArrayList<JsonValue>
        if (this.queryWithHistoryMsg) {
            messages = this.history_messages
        }else {
            messages = ArrayList<JsonValue>()  
            let systemQuery = JsonObject()
            systemQuery.put("role", JsonString("system"))
            systemQuery.put("content", JsonString("You are a helpful assistant."))
            messages.append(systemQuery)
        }
        // let multi_role_content = JsonValue.fromStr(content).asObject()
        // println(multi_role_content)
        // let user = multi_role_content.get("user").getOrThrow().asString()
        // println(user)
        // let system = multi_role_content.get("system").getOrThrow().asString()
        // println(system)
        let userQuery = JsonObject()
        userQuery.put("role", JsonString("user"))
        userQuery.put("content", JsonString(content))
        messages.append(userQuery)

        var data = JsonObject()
        // data.put("model", JsonString("gpt-4"))
        data.put("model", JsonString(this.model))
        data.put("temperature", JsonFloat(0.7))
        data.put("messages", JsonArray(messages))
        if (stop){
            data.put("stop", JsonString("Observation:"))
        }
        // println(data.toJsonString())
        return data.toJsonString()
    }
    
    func creatFunctionCallingQueryPostData(content: String, tools: ArrayList<JsonValue>) {
        let messages:ArrayList<JsonValue> = ArrayList<JsonValue>()
        let userQuery = JsonObject()
        userQuery.put("role", JsonString("user"))
        userQuery.put("content", JsonString(content))
        messages.append(userQuery)

        var data = JsonObject()
        // data.put("model", JsonString("gpt-4"))
        data.put("model", JsonString(this.model))
        data.put("temperature", JsonFloat(0.7))
        data.put("messages", JsonArray(messages))
        data.put("tool_choice", JsonString("auto"))
        data.put("tools", JsonArray(tools))

        return data.toJsonString()
    }
    func creatEmbeddingQueryPostData(content: String,model:String) {
        var data = JsonObject()
        data.put("model", JsonString(model))
        data.put("input", JsonString(content))
        return data.toJsonString()
    }

    func recordResponse(role:String,content:String){
        let rep = JsonObject()
        rep.put("role", JsonString(role))
        rep.put("content", JsonString(content))
        this.history_messages.append(rep)
    }

    func string2JsonObject(response: String):JsonObject{

        let data: JsonObject
        try {
            data = JsonValue.fromStr(response).asObject()
        } catch (e: JsonException) {
            println(response)
            throw e
        }
        return data
    }

    func processChatQueryRepsonse(response: String): String {
        // println("response:${response}")
        let rep = string2JsonObject(response) 
        match (rep.get("error")) {
            case Some(error) => throw Exception(error.toJsonString())
            case None =>
                return match (rep.get("choices")) {
                    case Some(choices) =>
                        let jsonArray = choices.asArray()
                        let theFirst = jsonArray[0].asObject()
                        let message = 
                            theFirst.get("message").getOrThrow().asObject().get("content").getOrThrow().asString().getValue()
                        if (this.queryWithHistoryMsg) {
                            let role =  theFirst.get("message").getOrThrow().asObject().get("role").getOrThrow().asString().getValue()
                            this.recordResponse(role,message)
                        }
                        return message
                    case None => 
                        println("Something wrong with the response")
                        throw Exception(rep.toString())
                }
        }
    }

    func processFuncCallQueryResponse(response: String): JsonObject {
        // println("response:${response}")
        let rep = string2JsonObject(response) 
        match (rep.get("error")) {
            case Some(error) => throw Exception(error.toJsonString())
            case None =>
                return match (rep.get("choices")) {
                    case Some(choices) =>
                        let jsonArray = choices.asArray()
                        let theFirst = jsonArray[0].asObject()
                        if (theFirst.get("finish_reason").getOrThrow().asString().getValue() == "tool_calls") {
                            let tool_calls = 
                                theFirst.get("message").getOrThrow().asObject().get("tool_calls").getOrThrow().asArray()[0].asObject()

                            let function = tool_calls.get("function").getOrThrow().asObject()
                            let function_name = function.get("name").getOrThrow().asString().getValue()
                            let function_args = function.get("arguments").getOrThrow().asString().getValue()

                            var res = JsonObject()
                            res.put("function_name", JsonString(function_name))
                            res.put("function_args", JsonString(function_args))
                            res.put("tool_call", JsonBool(true))

                            return res
                            
                        }
                        else {
                            let message = 
                                theFirst.get("message").getOrThrow().asObject().get("content").getOrThrow().asString().getValue()
                            if (this.queryWithHistoryMsg) {
                                let role =  theFirst.get("message").getOrThrow().asObject().get("role").getOrThrow().asString().getValue()
                                this.recordResponse(role,message)
                            }
                            var res = JsonObject()
                            res.put("message", JsonString(message))
                            res.put("tool_call", JsonBool(false))
                            return res
                        }
                    case None => 
                        println("Something wrong with the response")
                        throw Exception(rep.toString())
                }
        }
    }

    func processChatQueryRepsonseWithStreamMode(response: String): String{
        /* Todo */
        // println(response)
        let json_arr = response.split("data:", removeEmpty: true)
        var result = ""
        // println(json_arr)
        for(str in json_arr){
            if (str == "[DONE]"){
                // println("done")
                continue
            }
            let rep: JsonObject
            try {
                rep = JsonValue.fromStr(str).asObject()
            } catch (e: Exception){
                // println("JsonStr err: ${str}")
                continue
            }
            let choices = match( rep.get("choices")){
                case Some(choice) => choice.asArray()
                case None => continue
            }
            var finish_reason=""
            for(item in choices.getItems()){
                let item_obj = (item as JsonObject).getOrThrow()
                // println(item_obj)
                finish_reason = item_obj.get("finish_reason").getOrThrow().toString()
                // println(finish_reason)
                let delta = (item_obj.get("delta").getOrThrow() as JsonObject).getOrThrow()
                // println(delta)
                let content = match(delta.get("content")){
                    case Some(data) => data.asString().getValue()
                    case None => continue
                }
                result = result + content
                // print(content)
            }
            if(finish_reason == "null") {
                continue
            } 
        }
        let fa_str_headers = Array<String>(["Final Answer:", "final answer"])
        var fa_idx = 0
        for(header in fa_str_headers){
            fa_idx = match(result.lastIndexOf(header)){
            case Some(idx) => idx + header.size
            case None => continue
            }
            if(fa_idx != 0) {
                break
            }
        }
        let final_answer = result[fa_idx..]
        return final_answer
    }

    func processEmbedQueryRepsonse(repsonse: String):Array<Float32>{
        func jsonArray2CJArray(jsonArray:JsonArray):Array<Float32>{
            let cjArray = Array<Float32>(jsonArray.size(),item:0.0)
            for (i in 0..jsonArray.size()) {
                cjArray[i] = Float32(jsonArray[i].asFloat().getValue())
            }
            return cjArray
        }
        let rep = string2JsonObject(repsonse) 
        let embedList =  rep.get("data").getOrThrow().asArray()
        let embedObject = embedList[0].asObject()
        let embeddingJsonArray = embedObject.get("embedding").getOrThrow().asArray()
        let array = jsonArray2CJArray(embeddingJsonArray)
        return array
    }

    public func query(content: String, stop!:Bool = false): String {
        let postData = this.creatChatQueryPostData(content, stop:stop)
        let query = unsafe { LibC.mallocCString(postData) }
        // println("chatUrl:${chatUrl}")
        let response = unsafe { send_llm_request(this.authHeader, this.chatUrl, this.response, this.bufferSize, query) }
        let result = response.toString()
        unsafe {
            LibC.free(query)
        }
        println("")
        if (this.queryWithStreamMode){
            return processChatQueryRepsonseWithStreamMode(result)
        }
        return processChatQueryRepsonse(result)
    }

    public func queryFunctionCall(content: String, tools: ArrayList<JsonValue>): JsonObject{
        let postData = this.creatFunctionCallingQueryPostData(content, tools)
        println(postData)
        let query = unsafe { LibC.mallocCString(postData) }
        // println("authHeader:${authHeader}")
        // println("chatUrl:${chatUrl}")
        let repsonse = unsafe { send_llm_request(this.authHeader, this.chatUrl, this.response, this.bufferSize, query) }
        let result = repsonse.toString()
        unsafe {
            LibC.free(query)
        }
        return processFuncCallQueryResponse(result)
    }

    /*
    Refer to https://platform.openai.com/docs/guides/embeddings/what-are-embeddings for more details about the model options
    The function will encode this input text and output a single vector embedding with 1536 dimensions
    */
    public func embedding(content: String,model!:String="text-embedding-ada-002"): Array<Float32> {
        let postData = this.creatEmbeddingQueryPostData(content,model)
        let query = unsafe { LibC.mallocCString(postData) }
        let repsonse = unsafe { send_llm_request(this.authHeader, this.embeddingUrl, this.response, this.bufferSize, query) }
        let result = repsonse.toString()
        unsafe {
            LibC.free(query)
        }
        return processEmbedQueryRepsonse(result)
    }
    ~init() {
        unsafe{ LibC.free(response) }
    }
}


