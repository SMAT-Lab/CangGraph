package tool
from encoding import json.*
from std import collection.*
import schema.*

public interface Runnable {
    func run(args : Array<Any>) : Any
    func invoke(args: JsonObject): String
    func invoke(args: Dict): JsonObject
}

public struct Args {
    public var name: String
    public var description: String
    public var isRequired: Bool
    public var arg_type: String

    public init(name: String, description: String, isRequired: Bool, arg_type!: String = "string") {
        this.name = name
        this.description = description
        this.isRequired = isRequired
        this.arg_type = arg_type
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
        this.args_schema = get_tool_args()
    }

    public func get_tool_args(): JsonObject {
        var properties = JsonObject()
        var parameters = JsonObject()
        var required = JsonArray()
        var function = JsonObject()
        var args_schema = JsonObject()

        for (arg in this.args) {
            var arg_json = JsonObject()
            arg_json.put("type", JsonString(arg.arg_type))
            arg_json.put("description", JsonString(arg.description))
            properties.put(arg.name, arg_json)

            if (arg.isRequired) {
                required.add(JsonString(arg.name))
            }
        }

        parameters.put("type", JsonString("object"))
        parameters.put("properties", properties)
        parameters.put("required", required)

        function.put("name", JsonString(this.name))
        function.put("description", JsonString(this.description))
        function.put("parameters", parameters)

        args_schema.put("type", JsonString("function"))
        args_schema.put("function", function)

        return args_schema
    }

}

// function's parameter
public class Parameter {
    public var name: String
    public var description: String
    public var required: Bool

    public init(name: String, description: String, required: Bool) {
        this.name = name
        this.description = description
        this.required = required
    }

}

public class BaseFunction {
    public var name: String
    public var description: String
    public var parameters: HashMap<String, Parameter> = HashMap() // key: name, value: description

    public init(name: String, description: String, parameters: HashMap<String, Parameter>) {
        this.name = name
        this.description = description
        this.parameters = parameters
    }
}

// convert the base function to a json schema
public func get_function_schema(function: BaseFunction) {
    var properties = JsonObject()
    var parameters = JsonObject()
    var required = JsonArray()
    var function_json = JsonObject()
    var function_schema = JsonObject()

    for ((key, value) in function.parameters) {
        var arg_json = JsonObject()
        arg_json.put("type", JsonString("string"))
        arg_json.put("description", JsonString(value.description))
        properties.put(key, arg_json)

        if (value.required) {
            required.add(JsonString(key))
        }
    }
    
    parameters.put("type", JsonString("object"))
    parameters.put("properties", properties)
    parameters.put("required", required)

    function_json.put("name", JsonString(function.name))
    function_json.put("description", JsonString(function.description))
    function_json.put("parameters", parameters)

    function_schema.put("type", JsonString("function"))
    function_schema.put("function", function_json)

    return function_schema
}
