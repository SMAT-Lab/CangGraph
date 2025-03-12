package canggraph.tool

import canggraph.tool.utilities.*

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

    public func invoke(query: String): ResponseMessage {
        let content = (apiWrapper.run(query) as String).getOrThrow()
        return ResponseMessage("serpapi_search", content, false, Array<ToolCall>())
    }

    public func invoke(input:HashMap<String, String>): ResponseMessage {
        var query: String = input.get("query").getOrThrow()
        return invoke(query)
    }

    public func invoke(args: JsonObject): ResponseMessage {
        let query: String = args.get("query").getOrThrow().asString().getValue()
        return invoke(query)
    }
}