package canggraph.tool.utilities

import std.{os.*, socket.*}
import encoding.{json.*, url.*}

foreign func search(url: CString,  reponse: CPointer<UInt8>, bufferSize: UIntNative) : CString

public class GoogleSearchAPIWrapper 
{

    // google api key
    // create api key by https://developers.google.com/custom-search/v1/introduction?apix=true&hl=zh-cn
    private var api_key : String

    // google search engine id
    // create search engine id by https://www.google.com/cse/all
    private var search_engine_id : String
    private var url = unsafe { LibC.mallocCString("") }
    public let response: CPointer<UInt8>
    public var bufferSize: UIntNative
    private static let CLASS_NAME = "GoogleSearchAPIWrapper"

    //zhaorenhuo_key: AIzaSyBnyBzh_r88o7j4AtotqWwVmMBr9RQqW5g 
    //zhaorenhuoid:80da818a529554b8a
    public init(bufferSize!: UInt64 = 4096) {
        this.response = unsafe{ LibC.malloc<UInt8>(count:Int64(bufferSize))}
        // environments
        // let envs = envVars()
        // println(envs)
        
        try {
            api_key = getEnv("GOOGLE_API_KEY").getOrThrow()
            search_engine_id = getEnv("SEARCH_ENGINE_ID").getOrThrow()
        } catch (e : Exception) {
            println(CLASS_NAME + ": " + e.toString())
            api_key = "AIzaSyDtj86vYYVIt2wA4TPpbrerYweQSq4xaX0"
            search_engine_id = "f4ece9b85ae75403b"
        }
        this.bufferSize = UIntNative(bufferSize)
        println("google search tool init done")
    }
    
    public func run(query : String, num! : UInt64 = 1) {
        return get_google_result(query, num: num)
    }


    public func results(query : String, num! : UInt64 = 1) {
        let res = get_google_result(query, num: num)
        return res
    } 
    /**
      to get google result
    */
    private func get_google_result(query : String, num! : UInt64 = 1) {
        let url_str = "https://customsearch.googleapis.com/customsearch/v1?key=${api_key}&num=${num}&q=${query}&cx=${search_engine_id}"
        this.url = unsafe { LibC.mallocCString(url_str) }

        let repsonse = unsafe { search(this.url, this.response, this.bufferSize) }
        let cjrepsonse = repsonse.toString()
        let jv: JsonObject = (JsonValue.fromStr(cjrepsonse) as JsonObject).getOrThrow()
        let items = (jv.get("items").getOrThrow() as JsonArray).getOrThrow()
        var result = ""
        for(item in items.getItems()){
            let item_obj = (item as JsonObject).getOrThrow()
            let snippet = item_obj.get("snippet").getOrThrow().asString().getValue()
            result = result + snippet
        }
        unsafe {
            LibC.free(url)
        }
        return result
    }
    ~init() {
        unsafe { LibC.free(response) }
    }
}