package canggraph.util

public class ToolProperties <: Serializable<ToolProperties> {
    var propertiy_type: String
    var description: String

    public init() {
        this.propertiy_type = ""
        this.description = ""
    }

    public init(propertiy_type: String, description: String) {
        this.propertiy_type = propertiy_type
        this.description = description
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("type", propertiy_type))
        dms.add(field<String>("description", description))
        return dms
    }

    public static func deserialize(dm: DataModel): ToolProperties {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = ToolProperties()
        result.propertiy_type = String.deserialize(dms.get("type"))
        result.description = String.deserialize(dms.get("description"))

        return result
    }
}

public class ToolParameters <: Serializable<ToolParameters> {
    var param_type : String
    var properties: HashMap<String, ToolProperties>
    var required: Array<String>
    var additionalProperties: Bool

    public init() {
        this.param_type = ""
        this.properties = HashMap<String, ToolProperties>()
        this.required = Array<String>()
        this.additionalProperties = false
    }

    public init(param_type: String, properties: HashMap<String, ToolProperties>, required: Array<String>, additionalProperties: Bool) {
        this.param_type = param_type
        this.properties = properties
        this.required = required
        this.additionalProperties = additionalProperties
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("type", param_type))
        dms.add(field<HashMap<String, ToolProperties>>("properties", properties))
        dms.add(field<Array<String>>("required", required))
        dms.add(field<Bool>("additionalProperties", additionalProperties))
        return dms
    }

    public static func deserialize(dm: DataModel): ToolParameters {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = ToolParameters()
        result.param_type = String.deserialize(dms.get("type"))
        result.properties = HashMap<String, ToolProperties>.deserialize(dms.get("properties"))
        result.required = Array<String>.deserialize(dms.get("required"))
        result.additionalProperties = Bool.deserialize(dms.get("additionalProperties"))

        return result
    }

}

public class ToolArgs <: Serializable<ToolArgs> {

    var tool_name: String
    var tool_description: String
    var parameters: ToolParameters

    public init() {
        this.tool_name = ""
        this.tool_description = ""
        this.parameters = ToolParameters()
    }

    public init(tool_name: String, tool_description: String, parameters: ToolParameters) {
        this.tool_name = tool_name
        this.tool_description = tool_description
        this.parameters = parameters
    }   

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("name", tool_name))
        dms.add(field<String>("description", tool_description))
        dms.add(field<ToolParameters>("parameters", parameters))
        return dms
    }

    public static func deserialize(dm: DataModel): ToolArgs {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = ToolArgs()
        result.tool_name = String.deserialize(dms.get("tool_name"))
        result.tool_description = String.deserialize(dms.get("tool_description"))
        result.parameters = ToolParameters.deserialize(dms.get("parameters"))

        return result
    }
}

public class Tool <: Serializable<Tool> {
    var tool_type: String
    var function: ToolArgs

    public init() {
        this.tool_type = ""
        this.function = ToolArgs()
    }

    public init(tool_type: String, function: ToolArgs) {
        this.tool_type = tool_type
        this.function = function
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("type", tool_type))
        dms.add(field<ToolArgs>("function", function))
        return dms
    }

    public static func deserialize(dm: DataModel): Tool {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = Tool()
        result.tool_type = String.deserialize(dms.get("type"))
        result.function = ToolArgs.deserialize(dms.get("function"))

        return result
    }
}

public class ToolCall <: Serializable<ToolCall> {
    var id: String = ""
    var name: String
    var arguments: HashMap<String, String>

    public init() {
        this.name = ""
        this.arguments = HashMap<String, String>()
    }

    public init(name: String, arguments: HashMap<String, String>) {
        this.name = name
        this.arguments = arguments
    }

    public init(name: String, arguments: HashMap<String, String>, id: String) {
        this.name = name
        this.arguments = arguments
        this.id = id
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("name", name))
        dms.add(field<HashMap<String, String>>("arguments", arguments))
        dms.add(field<String>("id", id))
        return dms
    }

    public static func deserialize(dm: DataModel): ToolCall {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = ToolCall()
        result.name = String.deserialize(dms.get("name"))
        result.arguments = HashMap<String, String>.deserialize(dms.get("arguments"))
        result.id = String.deserialize(dms.get("id"))

        return result
    }
}