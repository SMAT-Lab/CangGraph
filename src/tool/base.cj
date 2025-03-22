package canggraph.tool

import canggraph.schema.*
import canggraph.util.Runnable
import canggraph.util.Tool
import canggraph.util.ResponseMessage
import canggraph.util.Message
import canggraph.util.ToolProperties
import canggraph.util.ToolParameters
import canggraph.util.ToolArgs

import std.collection.*
import encoding.json.*

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

    public var tool: Tool

    // contruction
    public init() {
        this.name = ""
        this.description = ""
        this.args = ArrayList<Args>()
        this.tool = Tool()
    }

    // contruction with name and description
    public init(_name : String, _description : String) {
        this.name = _name
        this.description = _description
        this.args = ArrayList<Args>()
        this.tool = Tool()
    }

    public init(_name : String, _description : String, _args: ArrayList<Args>) {
        this.name = _name
        this.description = _description
        this.args = _args
        this.tool = Tool()
    }

    public func invoke(input: String): ResponseMessage

    public func setArgs() {
        this.args_schema = get_tool_args()
        this.tool = get_tool()
    }

    public func get_tool(): Tool {
        let tool_properties = HashMap<String, ToolProperties>()

        let required: ArrayList<String> = ArrayList<String>()

        for (arg in this.args) {
            tool_properties.put(arg.name, ToolProperties(arg.arg_type, arg.description))
            if (arg.isRequired) {
                required.append(arg.name)
            }
        }

        let required_array = required.toArray()
        let tool_parameters = ToolParameters("object", tool_properties, required_array, false)
    
        let tool_args = ToolArgs(this.name, this.description, tool_parameters)
        return Tool("function", tool_args)
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

    public func get_function_tool(): Tool {
        let tool_properties = HashMap<String, ToolProperties>()

        let required: ArrayList<String> = ArrayList<String>()

        for ((name, param) in parameters) {
            tool_properties.put(param.name, ToolProperties("string", param.description))
            if (param.required) {
                required.append(param.name)
            }
        }

        let required_array = required.toArray()
        let tool_parameters = ToolParameters("object", tool_properties, required_array, false)

        let tool_args = ToolArgs(name, description, tool_parameters)
        return Tool("function", tool_args)
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

