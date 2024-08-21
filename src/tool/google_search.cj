package tool

import tool.utilities.GoogleSearchAPIWrapper


/**
  the google search tool
*/
public class GoogleSearchRun <: BaseTool {

    // to search things by Google
    private let apiWrapper : GoogleSearchAPIWrapper

    public init() {

        // name 
        this.name = "google_search"

        // description
        this.description = "A wrapper around Google Search. " + 
            "Useful for when you need to answer questions about current events. " + 
            "Input should be a search query."

        this.apiWrapper = GoogleSearchAPIWrapper(bufferSize: 10240)
        this.args = ArrayList<Args>([Args("query", "query to search, mustn't contain any special characters.", true)])
        this.setArgs()
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

    public func invoke(query: String): ResponseMessage {
        let content = (run([query]) as String).getOrThrow()
        return ResponseMessage("google_search", content, false, Array<ToolCall>())
    }

    public func invoke(input:HashMap<String, String>): ResponseMessage {
        var query: String = input.get("query").getOrThrow()
        return invoke(query)
    }

    public func invoke(args: JsonObject): ResponseMessage {
        var query: String = args.get("query").getOrThrow().asString().getValue()
        return invoke(query)
    }
}