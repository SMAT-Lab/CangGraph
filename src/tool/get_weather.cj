package tool

import tool.utilities.*
from std import fs.*

public class GetWeather <: BaseTool {

    public init() {

        // name 
        this.name = "get_weather"

        // description
        this.description = "Get the current weather of a city"
        this.args = ArrayList<Args>([Args("location", "The city and state", true)])
        this.setArgs()
    }

    // public func setArgs() {
    //     var location = JsonObject()
    //     location.put("type", JsonString("string"))
    //     location.put("description", JsonString("The city and state, e.g. New York, NY"))

    //     var properties = JsonObject()
    //     properties.put("location", location)

    //     var required = JsonArray()
    //     required.add(JsonString("location"))

    //     var parameters = JsonObject()
    //     parameters.put("type", JsonString("object"))
    //     parameters.put("properties", properties)
    //     parameters.put("required", required)

    //     var function = JsonObject()
    //     function.put("name", JsonString(this.name))
    //     function.put("description", JsonString(this.description))
    //     function.put("parameters", parameters)

    //     var args = JsonObject()
    //     args.put("type", JsonString("function"))
    //     args.put("function", function)

    //     this.args_schema = args
    // }

    public func run(query : String): String {
        println("running getting weather")
        (run(["temp.py", query]) as String).getOrThrow()
    }

    public func run(filename: String, content: String): String {
        println("running getting weather")
        (run([filename, content]) as String).getOrThrow()
    }

    
    public func run(args : Array<Any>) : Any {
        let filename = (args[0] as String).getOrThrow()
        return filename
    }

    public func run(args: JsonObject): String {
        // def get_current_weather(location: str) -> str:
        //    return f"the weather in {location} is 72 degrees Fahrenheit with clear skies."
        let location = args.get("location").getOrThrow()
        return "the weather in ${location} is 72 degrees Fahrenheit with clear skies."
    }

    ~init() {
    }
    
}