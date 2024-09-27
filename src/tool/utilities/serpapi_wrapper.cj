package tool.utilities

import schema.*

from std import collection.*, os.*, socket.*
from encoding import json.*, url.*

foreign func serpapi_search(url: CString,  reponse: CPointer<UInt8>, bufferSize: UIntNative) : CString

public class SerpAPIWrapper 
{

    // google api key
    // create api key by https://serpapi.com/dashboard
    private var api_key : String
    private var url = unsafe { LibC.mallocCString("") }
    public let response: CPointer<UInt8>
    public var bufferSize: UIntNative
    private static let CLASS_NAME = "SerpAPIWrapper"

    //zhaorenhuo_key: 8c05a6f87241931cc2ea55d279ffd22708aa5d516e497357a38e5044e33aa829
    public init(bufferSize!: UInt64 = 4096) {
        this.response = unsafe{ LibC.malloc<UInt8>(count:Int64(bufferSize))}
        // environments
        // let envs = envVars()
        // println(envs)
        
        try {
            api_key = getEnv("SERP_API_KEY").getOrThrow()
        } catch (e : Exception) {
            println(CLASS_NAME + ": " + e.toString())
            api_key = "8c05a6f87241931cc2ea55d279ffd22708aa5d516e497357a38e5044e33aa829"
        }
        this.bufferSize = UIntNative(bufferSize)
        println("serpapi tool init done")
    }
    
    public func run(query : String, num! : UInt64 = 1) {
        return get_serpapi_result(query, num: num)
    }


    public func results(query : String, num! : UInt64 = 1) {
        let res = get_serpapi_result(query, num: num)
        return res
    } 
    /**
      to get google result
    */
    private func get_serpapi_result(query : String, num! : UInt64 = 1) {
        let url_str = "https://serpapi.com/search?key=${api_key}&num=${num}&q=${query}"
        // let url_str = "https://serpapi.com/search?key=${api_key}&q=${query}"
        // println(url_str)
        this.url = unsafe { LibC.mallocCString(url_str) }

        let repsonse = unsafe { serpapi_search(this.url, this.response, this.bufferSize) }
        let cjrepsonse = repsonse.toString()
        let jv: JsonObject = (JsonValue.fromStr(cjrepsonse) as JsonObject).getOrThrow()
        var result = process_response(jv)
        // let items = (jv.get("items").getOrThrow() as JsonArray).getOrThrow()
        // var result = ""
        // for(item in items.getItems()){
        //     let item_obj = (item as JsonObject).getOrThrow()
        //     let snippet = item_obj.get("snippet").getOrThrow().asString().getValue()
        //     result = result + snippet
        // }
        unsafe {
            LibC.free(url)
        }
        return result
    }

    private func process_response(res: JsonObject){
        // """Process response from SerpAPI."""
        if (res.containsKey("error")) {
            throw Exception("Got error from SerpAPI: ${res["error"]}")
        }
        if (res.containsKey("answer_box_list")) {

            // let ans = res.get("answer_box_list")
            // var answer_box: JsonValue = match(ans) {
            //     case Some(x) => x
            //     case None => throw Exception("No answer box found")
            // }
            // res.put("answer_box", answer_box)
            res.put("answer_box", res.get("answer_box_list").getOrThrow())
        }

        if(res.containsKey("answer_box")) {
            let items = (res.get("answer_box").getOrThrow() as JsonArray).getOrThrow()
            var answer = (items.get(0).getOrThrow() as JsonObject).getOrThrow()
            if(answer.containsKey("result")) {
                return answer.get("result").getOrThrow()
            } else if(answer.containsKey("answer")) {
                return answer.get("answer").getOrThrow()
            } else if(answer.containsKey("snippet")) {
                return answer.get("snippet").getOrThrow()
            } else if(answer.containsKey("snippet_highlighted_words")) {
                return answer.get("snippet_highlighted_words").getOrThrow()
            }
            else {
                return answer.toString()
            }
        }
        else if (res.containsKey("events_results")) {
            return res.get("events_results").getOrThrow()
        }
        else if (res.containsKey("sports_results")) {
            return res.get("sports_results").getOrThrow()
        }
        else if (res.containsKey("news_results")) {
            return res.get("news_results").getOrThrow()
        }
        else if (res.containsKey("top_stories")) {
            return res.get("top_stories").getOrThrow()
        }
        else if (res.containsKey("news_results")) {
            return res.get("news_resultss")
        }
        else if (res.containsKey("jobs_results")) {
            let m = (res.get("news_results") as JsonObject).getOrThrow()
            if (m.containsKey("jobs")) {
                return m.get("jobs").getOrThrow()
            }
        }
        else if (res.containsKey("shopping_results")) {
            let m = (res.get("shopping_results") as JsonArray).getOrThrow()
            let m0 = (m[0] as JsonObject).getOrThrow()
            if (m0.containsKey("title")) {
                // return m0.get("title").getOrThrow()
                var list = ArrayList<JsonValue>()
                list.append(m[0])
                list.append(m[1])
                list.append(m[2])
                return list
            }
        }
        else if (res.containsKey("questions_and_answers")) {
            return res.get("questions_and_answers").getOrThrow()
        }
        else if (res.containsKey("popular_destinations")) {
            let m = (res.get("popular_destinations").getOrThrow() as JsonObject).getOrThrow()
            if (m.containsKey("destinations")) {
                return m.get("destinations").getOrThrow()
            }
        }
        else if (res.containsKey("top_sights")) {
            let m = (res.get("top_sights").getOrThrow() as JsonObject).getOrThrow()
            if (m.containsKey("sights")) {
                return m.get("sights").getOrThrow()
            }
        }
        else if (res.containsKey("images_results")) {
            let m = (res.get("images_results").getOrThrow() as JsonArray).getOrThrow()
            let m0 = (m[0] as JsonObject).getOrThrow()
            if (m0.containsKey("thumbnail")) {
                var list = ArrayList<JsonValue>()
                for (i in 0..10){
                    list.append(m[i])
                }
                var list_JsonArray = (list as JsonArray).getOrThrow()
                for (item in list_JsonArray.getItems()) {
                    let item_obj = (item as JsonObject).getOrThrow()
                    let thumbnail = item_obj.get("thumbnail").getOrThrow()
                    return thumbnail
                }
            }
        }

        var snippets = ArrayList<String>()
        if (res.containsKey("knowledge_graph")) {
            let knowledge_graph = (res.get("knowledge_graph").getOrThrow() as JsonObject).getOrThrow()
            let title = knowledge_graph.get("title").getOrThrow()
            if (knowledge_graph.containsKey("description")) {
                var description: String = knowledge_graph.get("description").getOrThrow().toString()
                snippets.append(description)
            }


            for ((key, v) in knowledge_graph.getFields()) {
                let value = v.toString()
                if (key is String && value is String && key != "title" && key != "description" && !key.endsWith("_stick") && !key.endsWith("_link") && !value.startsWith("http")) {
                    snippets.append("${title} ${key}: ${value}.")
                }
            }
        }

        if (res.containsKey("organic_results")) {
            let organic_results = (res.get("organic_results").getOrThrow() as JsonArray).getOrThrow()
            for (organic_result in organic_results.getItems()) {
                let organic_result_obj = (organic_result as JsonObject).getOrThrow()
                if (organic_result_obj.containsKey("snippet")) {
                    snippets.append(organic_result_obj.get("snippet").getOrThrow().toString())
                }
                else if (organic_result_obj.containsKey("snippet_highlighted_words")) {
                    snippets.append(organic_result_obj.get("snippet_highlighted_words").getOrThrow().toString())
                }
                else if (organic_result_obj.containsKey("rich_snippet")) {
                    snippets.append(organic_result_obj.get("rich_snippet").getOrThrow().toString())
                }
                else if (organic_result_obj.containsKey("rich_snippet_table")) {
                    snippets.append(organic_result_obj.get("rich_snippet_table").getOrThrow().toString())
                }
                else if (organic_result_obj.containsKey("link")) {
                    snippets.append(organic_result_obj.get("link").getOrThrow().toString())
                }
            }
        }

        if (res.containsKey("buying_guide")) {
            snippets.append((res.get("buying_guide").getOrThrow() as String).getOrThrow())
        }

        if (res.containsKey("local_results") && res.get("local_results").getOrThrow() is JsonArray) {
            let local_results = (res.get("local_results").getOrThrow() as JsonArray).getOrThrow()
            for (local_result in local_results.getItems()) {
                snippets.append((local_result as String).getOrThrow())
            }
        }

        if (res.containsKey("local_results") && res.get("local_results").getOrThrow() is JsonObject && (res.get("local_results").getOrThrow() as JsonObject).getOrThrow().containsKey("places")) {
            let place = ((res.get("local_results").getOrThrow() as JsonObject).getOrThrow().get("places").getOrThrow() as String).getOrThrow()
            snippets.append(place)
        }

        if (snippets.size > 0) {
            return snippets.toString()
        }
        else {
            return "No good search result found"
        }
        
    }

    ~init() {
        unsafe { LibC.free(response) }
    }
}