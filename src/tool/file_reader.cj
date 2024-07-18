package tool

import tool.utilities.*
from std import fs.*

public class FileReader <: BaseTool {

    public init() {

        // name 
        this.name = "file_reader"

        // description
        this.description = "When you need to read file, you use this tool to get the content from a file"
        let filename: Args = Args("filename", "filename to read", true)
        this.args = ArrayList<Args>([filename])
        this.setArgs()
    }

    // public func setArgs() {
    //     var filename = JsonObject()
    //     filename.put("type", JsonString("string"))
    //     filename.put("description", JsonString("filename to read"))

    //     var properties = JsonObject()
    //     properties.put("filename", filename)

    //     var required = JsonArray()
    //     required.add(JsonString("filename"))

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
        println("running file reader")
        (run(["temp.py", query]) as String).getOrThrow()
    }

    public func run(args : Array<Any>) : Any {
        let filename = (args[0] as String).getOrThrow()
        let allBytes: Array<Byte> = File.readFrom(filename)
        println(String.fromUtf8(allBytes))
        return "read successfully"
    }

    public func run(args: JsonObject): String {
        let filename: String = args.get("filename").getOrThrow().asString().getValue()
        let allBytes: Array<Byte> = File.readFrom(filename)
        return String.fromUtf8(allBytes)
    }

    ~init() {
    }
    
}