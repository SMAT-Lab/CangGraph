package tool

import tool.utilities.*
from std import fs.*

public class GetWeather <: BaseTool {

    public init() {

        // name 
        this.name = "get_weather"

        // description
        this.description = "Get the current weather of a city"
        this.args = ArrayList<Args>([Args("location", "The city and state", true), Args("time", "The time of the weather", false)])
        this.setArgs()
    }

    public func run(location : String): String {
        println("running getting weather")
        (run([location, "today"]) as String).getOrThrow()
    }
    
    public func run(args : Array<Any>) : Any {
        let location = (args[0] as String).getOrThrow()
        let time = (args[1] as String).getOrThrow()
        return "the weather in ${location} ${time} is 72 degrees Fahrenheit with clear skies."
    }

    public func invoke(args: Dict): JsonObject {
        println("running getting weather")
        let location = args["location"]
        var time = "today"
        if (args.contains("time")) {
            time = args["time"]
        }
        let res = JsonObject()
        res.put("content",JsonString((run([location, time]) as String).getOrThrow()))
        return res
    }

    public func invoke(args: JsonObject): String {
        println("running getting weather")
        let location: String = args.get("location").getOrThrow().asString().getValue()
        var time: String = "today"
        if (args.containsKey("time")) {
            time = args.get("time").getOrThrow().asString().getValue()
        }
        (run([location, time]) as String).getOrThrow()
    }

    ~init() {
    }
    
}