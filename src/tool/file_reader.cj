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

    public func invoke(args: Dict): JsonObject {
        let filename: String = args["filename"]
        let allBytes: Array<Byte> = File.readFrom(filename)
        let res = JsonObject()
        res.put("content", JsonString(String.fromUtf8(allBytes)))
        return res
    }

    public func invoke(args: JsonObject): String {
        let filename: String = args.get("filename").getOrThrow().asString().getValue()
        let allBytes: Array<Byte> = File.readFrom(filename)
        return String.fromUtf8(allBytes)
    }

    ~init() {
    }
    
}