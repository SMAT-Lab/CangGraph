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

    // public func setArgs() {
    //     var filename = JsonObject()
    //     filename.put("type", JsonString("string"))
    //     filename.put("description", JsonString("filename to save"))

    //     var content = JsonObject()
    //     content.put("type", JsonString("string"))
    //     content.put("description", JsonString("the content to be saved"))

    //     var properties = JsonObject()
    //     properties.put("filename", filename)
    //     properties.put("content", content)

    //     var required = JsonArray()
    //     required.add(JsonString("filename"))
    //     required.add(JsonString("content"))

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
        println("running file saver")
        (run(["temp.py", query]) as String).getOrThrow()
    }

    public func run(filename: String, content: String): String {
        println("running file saver")
        (run([filename, content]) as String).getOrThrow()
    }

    
    public func run(args : Array<Any>) : Any {
        let filename = (args[0] as String).getOrThrow()
        let query = (args[1] as String).getOrThrow()
        var file: File = File(filename, OpenOption.CreateOrTruncate(true))
        if(File.exists(filename)) {
            println("${filename} is create successfully in current directory.\n")
        }
        let bytes: Array<Byte> = query.toArray()// query.toUtf8Array()
        file.write(bytes)
        file.close()
        return "saved successfully"
    }

    public func run(args: JsonObject): String {
        let filename: String = args.get("filename").getOrThrow().asString().getValue()
        let content: String = args.get("content").getOrThrow().asString().getValue()

        var file: File = File(filename, OpenOption.CreateOrTruncate(true))
        if(File.exists(filename)) {
            println("${filename} is create successfully in current directory.\n")
        }
        let bytes: Array<Byte>= content.toArray()
        file.write(bytes)
        file.close()
        return "saved successfully"
    }

    ~init() {
    }
    
}