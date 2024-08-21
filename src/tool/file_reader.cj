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

    public func invoke(filename: String): ResponseMessage {
        let allBytes: Array<Byte> = File.readFrom(filename)
        let content = String.fromUtf8(allBytes)
        return ResponseMessage("file_reader", content, false, Array<ToolCall>())
    }

    public func invoke(input: HashMap<String, String>): ResponseMessage {
        let filename: String = input.get("filename").getOrThrow()
        return invoke(filename)
    }

    public func invoke(args: JsonObject): ResponseMessage {
        let filename: String = args.get("filename").getOrThrow().asString().getValue()
        return invoke(filename)
    }

    ~init() {
    }
    
}