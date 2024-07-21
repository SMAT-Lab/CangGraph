package tool
from std import ffi.python.*
from std import collection.*

public class pythonREPL <: BaseTool {
    public init() {
        this.name = "pythonREPL"
        this.description = "A wrapper to run python code"
        this.args = ArrayList<Args>([Args("code", "The python code to run", true), Args("filename", "save file name", true), Args("arguments", "The arguments to pass to the python code", false, arg_type: "object")])
        this.setArgs()
    }

    public func run(query: String): String {
        println("running python code")
        return (run([query]) as String).getOrThrow()
    }

    public func run(args : Array<Any>) : Any {
        Python.load()

        // Import .py file.
        var test = Python.Import("test01")

        // `set []` set the value of a to 20.
        test["a"] = Python.Eval("20")
        test["function"]()            // a is 20

        // Call function02 with a named argument.
        test["function02"]([1], HashMap<String, PyObj>([("c", 2.toPyObj())]))

        Python.unload()
    }

    public func avoke(args: JsonObject): String {
        let query = args.get("code").getOrThrow().asString().getValue()
        var filename = ""
        if (args.containsKey("filename")) {
            filename = args.get("filename").getOrThrow().asString().getValue()
        }
        else {
            filename = "test01"
        }
        if (args.containsKey("arguments")) {
            let arguments = args.get("arguments").getOrThrow()
        }

        FileSaver().run("${filename}.py", query)

        Python.load()
        // Import .py file.
        var test = Python.Import(filename)

        // Call function02 with a named argument.
        // test["function02"]([1, 2], HashMap<String, PyObj>([("c", 2.toPyObj())]))
        let sum: PyObj = test["add"]([1, 2])
        var res = sum.toString()
        Python.unload()
        return res
        // return sum.toString()
    }

    public func avoke(args: Dict): JsonObject {
        let query = args["code"]
        if (args.contains("arguments")) {
            let arguments = args["arguments"]
        }
        var filename = ""
        if (args.contains("filename")) {
            filename = args["filename"]
        }
        else {
            filename = "test01"
        }

        FileSaver().run("${filename}.py", query)


        Python.load()
        // Import .py file.
        var test = Python.Import(filename)

        // Call function02 with a named argument.
        // test["function02"]([1, 2], HashMap<String, PyObj>([("c", 2.toPyObj())]))
        let sum: PyObj = test["main"]()
        var res = JsonObject()
        res.put("content", JsonString(sum.toString()))
        Python.unload()
        return res
    }

}
