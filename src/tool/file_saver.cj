package tool

import tool.utilities.*
from std import fs.*

public class FileSaver <: BaseTool {

    public init() {
        // name 
        this.name = "file_saver"
        // description
        this.description = "When you need to save file, you must use this tool to save the content to a file"
        this.args = ArrayList<Args>([Args("filename", "filename to save", true), Args("content", "the content to be saved", true)])
        this.setArgs()
    }

    public func invoke(input: String): ResponseMessage {
        return invoke(input, "temp.py")
    }

    public func invoke(content: String, filename: String): ResponseMessage {
        var file: File = File(filename, OpenOption.CreateOrTruncate(true))
        if(File.exists(filename)) {
            println("${filename} is create successfully in current directory.\n")
        }
        let bytes: Array<Byte>= content.toArray()
        file.write(bytes)
        file.close()
        return ResponseMessage("file_saver", "file saved successfully", false, Array<ToolCall>())
    }

    public func invoke(input: HashMap<String, String>): ResponseMessage {
        let filename: String = input.get("filename").getOrThrow()
        let content: String = input.get("content").getOrThrow()
        return invoke(content, filename)
    }

    public func invoke(args: JsonObject): ResponseMessage {
        let filename: String = args.get("filename").getOrThrow().asString().getValue()
        let content: String = args.get("content").getOrThrow().asString().getValue()

        return invoke(content, filename)
    }

    ~init() {
    }
    
}