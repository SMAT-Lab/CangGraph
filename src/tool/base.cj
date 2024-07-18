package tool
from encoding import json.*
from std import collection.*
import schema.*

public interface Runnable {

    func run(args : Array<Any>) : Any

    func run(query : String) : String

    func run(args: JsonObject): String

}

public struct Args {
    public var name: String
    public var description: String
    public var isRequired: Bool

    public init(name: String, description: String, isRequired: Bool) {
        this.name = name
        this.description = description
        this.isRequired = isRequired
    }
}

/** 
 the super class of the tools
*/
public abstract class BaseTool <: Runnable {


    // the name of the tool
    public var name : String

    // the description of the tool
    public var description : String

    public var args: ArrayList<Args>

    public var args_schema: Option<JsonValue> = None
    

    // contruction
    public init() {
        this.name = ""
        this.description = ""
        this.args = ArrayList<Args>()
    }

    // contruction with name and description
    public init(_name : String, _description : String) {
        this.name = _name
        this.description = _description
        this.args = ArrayList<Args>()
    }

    public init(_name : String, _description : String, _args: ArrayList<Args>) {
        this.name = _name
        this.description = _description
        this.args = _args
    }

    public func setArgs() {
        this.args_schema = get_tool_args(this)
    }

}

public func get_tool_args(tool: BaseTool): JsonObject {
    let description = tool.description
    let name = tool.name
    let args = tool.args

    var properties = JsonObject()
    var parameters = JsonObject()
    var required = JsonArray()
    var function = JsonObject()
    var args_schema = JsonObject()

    for (arg in args) {
        var arg_json = JsonObject()
        arg_json.put("type", JsonString("string"))
        arg_json.put("description", JsonString(arg.description))
        properties.put(arg.name, arg_json)

        if (arg.isRequired) {
            required.add(JsonString(arg.name))
        }
    }
    
    parameters.put("type", JsonString("object"))
    parameters.put("properties", properties)
    parameters.put("required", required)

    function.put("name", JsonString(name))
    function.put("description", JsonString(description))
    function.put("parameters", parameters)

    args_schema.put("type", JsonString("function"))
    args_schema.put("function", function)

    return args_schema
}