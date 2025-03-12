package canggraph.tool

import canggraph.tool.utilities.*

import std.fs.*

public class GetWeather <: BaseTool {

    public init() {
        // name 
        this.name = "get_weather"
        // description
        this.description = "Get the current weather of a city"
        this.args = ArrayList<Args>([Args("location", "The city and state", true), Args("time", "The time of the weather", false)])
        this.setArgs()
    }

    public func run(args : Array<Any>) : Any {
        let location = (args[0] as String).getOrThrow()
        let time = (args[1] as String).getOrThrow()
        return "the weather in ${location} ${time} is 72 degrees Fahrenheit with clear skies."
    }

    public func invoke(input: String): ResponseMessage {
        return invoke(input, "today")
    }

    public func invoke(location: String, time: String): ResponseMessage {
        let content = (run([location, time]) as String).getOrThrow()
        return ResponseMessage("get_weather", content, false, Array<ToolCall>())
    }

    public func invoke(input: HashMap<String, String>): ResponseMessage {
        let location: String = input.get("location").getOrThrow()
        var time: String = "today"
        if (input.contains("time")) {
            time = input.get("time").getOrThrow()
        }
        return invoke(location, time)
    }

    public func invoke(args: JsonObject): ResponseMessage {
        println("running getting weather")
        let location: String = args.get("location").getOrThrow().asString().getValue()
        var time: String = "today"
        if (args.containsKey("time")) {
            time = args.get("time").getOrThrow().asString().getValue()
        }
        return invoke(location, time)
    }

    ~init() {
    }
    
}