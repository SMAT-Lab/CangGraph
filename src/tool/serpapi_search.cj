package tool

import tool.utilities.*

/**
  the google search tool
*/
public class SerpAPIRun <: BaseTool {

    // to search things by Google
    private let apiWrapper : SerpAPIWrapper

    public init() {

        // name 
        this.name = "serpapi_search"

        // description
        this.description = "A wrapper around Google Search. " + 
            "Useful for when you need to answer questions about current events. " + 
            "Input should be a search query."

        this.apiWrapper = SerpAPIWrapper(bufferSize: 40960)
        this.args = ArrayList<Args>([Args("query", "query to search, mustn't contain any special characters.", true)])
        this.setArgs()
    }

    public func run(query : String) {
        println("running serpapi search")
        (run([query]) as String).getOrThrow()
    }

    
    public func run(args : Array<Any>) : Any {
        var query = (args[0] as String).getOrThrow()
        query = handleString(query)
        apiWrapper.run(query)
    }

    public func handleString(query : String) {
        // 将特殊字符替换为空格
        var res = query.replace("[^a-zA-Z0-9]", " ")
        // 将空格替换为_
        res = res.replace(" ", "_")
        return res
    }


    public func invoke(args: JsonObject): String {
        let query: String = args.get("query").getOrThrow().asString().getValue()

        (apiWrapper.run(query) as String).getOrThrow()
    }

    public func invoke(args: Dict): JsonObject {
        var query: String = args["query"]
        var res = JsonObject()
        res.put("content", JsonString((run([query]) as String).getOrThrow()))
        return res
    }

    ~init() {
    }
    
}


/**
  the google search results tool
*/
public class SerpAPIResults <: BaseTool {

    // to search things by Google
    private let apiWrapper : SerpAPIWrapper

    // contruction
    public init() {
        // name 
        this.name = "SerpAPI Search Results JSON"

        // description
        this.description = "A wrapper around SerpAPI Search. " + 
            "Useful for when you need to answer questions about current events. " + 
            "Input should be a search query. Output is a JSON array of the query results"
        
        this.apiWrapper = SerpAPIWrapper(bufferSize: 40960)
    }

    public func run(query : String) {
        (run([query]) as String).getOrThrow()
    }

    public func run(args : Array<Any>) : Any {
        let query = (args[0] as String).getOrThrow()
        apiWrapper.results(query)
    }

    public func invoke(args: JsonObject): String {
        return run(args.toString())
    }

    public func invoke(args: Dict): JsonObject {
        var query: String = args["query"]
        var res = JsonObject()
        res.put("content", JsonString((run([query]) as String).getOrThrow()))
        return res
    }
    
    ~init() {
    }
}

// extend Option<T> {
//     public func isNone() : Bool {
//         match(this) {
//             case Some(v) => false
//             case None => true
//         }
//     }
// }