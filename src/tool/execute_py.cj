package tool

import tool.utilities.*
from encoding import json.*

/**
  the google search tool
*/

foreign func execute_python(query: CString) : CString
public class ExecutePythonRun <: BaseTool {
    public init() {

        // name 
        this.name = "ExecutePythonRun"

        // description
        this.description = "A wrapper to run python code"

        setArgs()
    }

    public func setArgs() {
        var args = JsonObject()
        args.put("type", JsonString("object"))
    }

    public func run(query: String): String {
        println("running python code")
        return (run([query]) as String).getOrThrow()
    }
    
    public func run(args : Array<Any>) : Any {
        
        let query: CString = unsafe { LibC.mallocCString((args[0] as String).getOrThrow()) }
        let result: CString = unsafe{ execute_python(query) }
        unsafe {
            LibC.free(query)
        }
        return result.toString()
    }

    public func run(args: JsonObject): String {
        return run(args.toString())
    }

    ~init() {
    }
    
}