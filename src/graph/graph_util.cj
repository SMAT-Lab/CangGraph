package canggraph.graph

import serialization.serialization.*
import encoding.json.*
import std.collection.*

public class GraphData <: Serializable<GraphData> {
    var nodes: Array<NodeData>
    var edges: Array<EdgeData>
    var position: Array<Float32>
    var zoom: Float32
    var viewport: HashMap<String, Float32>

    public init() {
        this.nodes = Array<NodeData>()
        this.edges = Array<EdgeData>()
        this.viewport = HashMap<String, Float32>()
        this.position = Array<Float32>(2, item: 0.1)
        this.zoom = 1.0
    }

    public init(nodes: Array<NodeData>, edges: Array<EdgeData>, position: Array<Float32>, zoom: Float32, viewport: HashMap<String, Float32>) {
        this.nodes = nodes
        this.edges = edges
        this.position = position
        this.zoom = zoom
        this.viewport = viewport
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<Array<NodeData>>("nodes", nodes))
        dms.add(field<Array<EdgeData>>("edges", edges))
        dms.add(field<Array<Float32>>("position", position))
        dms.add(field<Float32>("zoom", zoom))
        dms.add(field<HashMap<String, Float32>>("viewport", viewport))
        return dms
    }

    public static func deserialize(dm: DataModel): GraphData {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = GraphData()
        result.nodes = Array<NodeData>.deserialize(dms.get("nodes"))
        result.edges = Array<EdgeData>.deserialize(dms.get("edges"))
        result.position = Array<Float32>.deserialize(dms.get("position"))
        result.zoom = Float32.deserialize(dms.get("zoom"))
        result.viewport = HashMap<String, Float32>.deserialize(dms.get("viewport"))

        return result
    }

}

public class NodePropertiesData <: Serializable<NodePropertiesData> {
    var nodeName: String
    var isEntryPoint: Bool
    var isExitPoint: Bool
    var llm: String
    var tools: Array<String>

    public init() {
        this.nodeName = ""
        this.isEntryPoint = false
        this.isExitPoint = false
        this.llm = ""
        this.tools = Array<String>()
    }

    public init(nodeName: String, isEntryPoint: Bool, isExitPoint: Bool, llm: String, tools: Array<String>) {
        this.nodeName = nodeName
        this.isEntryPoint = isEntryPoint
        this.isExitPoint = isExitPoint
        this.llm = llm
        this.tools = tools
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("nodeName", nodeName))
        dms.add(field<Bool>("isEntryPoint", isEntryPoint))
        dms.add(field<Bool>("isExitPoint", isExitPoint))
        dms.add(field<String>("llm", llm))
        dms.add(field<Array<String>>("tools", tools))
        return dms
    }

    public static func deserialize(dm: DataModel): NodePropertiesData {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = NodePropertiesData()
        result.nodeName = String.deserialize(dms.get("nodeName"))
        result.isEntryPoint = Bool.deserialize(dms.get("isEntryPoint"))
        result.isExitPoint = Bool.deserialize(dms.get("isExitPoint"))
        result.llm = String.deserialize(dms.get("llm"))
        result.tools = Array<String>.deserialize(dms.get("tools"))

        return result
    }
}

public class NodeDataProps <: Serializable<NodeDataProps> {
    var propName: String
    var showName: String
    var propType: String
    var value: String
    var options: Array<String>

    public init() {
        this.propName = ""
        this.showName = ""
        this.propType = ""
        this.value = ""
        this.options = Array<String>()
    }

    public init(propName: String, showName: String, propType: String, value: String, options: Array<String>) {
        this.propName = propName
        this.showName = showName
        this.propType = propType
        this.value = value
        this.options = options
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("propName", propName))
        dms.add(field<String>("showName", showName))
        dms.add(field<String>("type", propType))
        dms.add(field<String>("value", value))
        dms.add(field<Array<String>>("options", options))
        return dms
    }

    public static func deserialize(dm: DataModel): NodeDataProps {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = NodeDataProps()
        result.propName = String.deserialize(dms.get("propName"))
        result.showName = String.deserialize(dms.get("showName"))
        result.propType = String.deserialize(dms.get("type"))
        result.value = String.deserialize(dms.get("value"))
        result.options = Array<String>.deserialize(dms.get("options"))

        return result
    }
}

public class NodeRawData <: Serializable<NodeRawData> {
    var compName: String
    var showName: String
    var props: Array<NodeDataProps>
    var invokeProps: Array<NodeDataProps>

    public init() {
        this.compName = ""
        this.showName = ""
        this.props = Array<NodeDataProps>()
        this.invokeProps = Array<NodeDataProps>()
    }

    public init(compName: String, showName: String, props: Array<NodeDataProps>, invokeProps: Array<NodeDataProps>) {
        this.compName = compName
        this.showName = showName
        this.props = props
        this.invokeProps = invokeProps
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("compName", compName))
        dms.add(field<String>("showName", showName))
        dms.add(field<Array<NodeDataProps>>("props", props))
        dms.add(field<Array<NodeDataProps>>("invokeProps", invokeProps))
        return dms
    }

    public static func deserialize(dm: DataModel): NodeRawData {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = NodeRawData()
        result.compName = String.deserialize(dms.get("compName"))
        result.showName = String.deserialize(dms.get("showName"))
        result.props = Array<NodeDataProps>.deserialize(dms.get("props"))
        result.invokeProps = Array<NodeDataProps>.deserialize(dms.get("invokeProps"))

        return result
    }
}

public class NodeData <: Serializable<NodeData> {
    var id: String
    var node_type: String
    var initialized: Bool
    var position: Array<Float32>
    var label: String
    var layerType: String
    var invokeData: HashMap<String, String>
    var data: NodePropertiesData
    var rawData: NodeRawData

    public init() {
        this.id = ""
        this.node_type = ""
        this.initialized = false
        this.position = Array<Float32>(2, item: 0.1)
        this.label = ""
        this.layerType = ""
        this.invokeData = HashMap<String, String>()
        this.data = NodePropertiesData()
        this.rawData = NodeRawData()
    }

    public init(id: String, node_type: String, initialized: Bool, position: Array<Float32>, label: String, layerType: String, invokeData: HashMap<String, String>, data: NodePropertiesData, rawData: NodeRawData) {
        this.id = id
        this.node_type = node_type
        this.initialized = initialized
        this.position = position
        this.label = label
        this.layerType = layerType
        this.invokeData = invokeData
        this.data = data
        this.rawData = rawData
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("id", id))
        dms.add(field<String>("type", node_type))
        dms.add(field<Bool>("initialized", initialized))
        dms.add(field<Array<Float32>>("position", position))
        dms.add(field<String>("label", label))
        dms.add(field<String>("layerType", layerType))
        dms.add(field<HashMap<String, String>>("invokeData", invokeData))
        dms.add(field<NodePropertiesData>("data", data))
        dms.add(field<NodeRawData>("rawData", rawData))
        return dms
    }

    public static func deserialize(dm: DataModel): NodeData {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = NodeData()
        result.id = String.deserialize(dms.get("id"))
        result.node_type = String.deserialize(dms.get("type"))
        result.initialized = Bool.deserialize(dms.get("initialized"))
        result.position = Array<Float32>.deserialize(dms.get("position"))
        result.label = String.deserialize(dms.get("label"))
        result.layerType = String.deserialize(dms.get("layerType"))
        result.invokeData = HashMap<String, String>.deserialize(dms.get("invokeData"))
        result.data = NodePropertiesData.deserialize(dms.get("data"))
        result.rawData = NodeRawData.deserialize(dms.get("rawData"))

        return result
    }
}

public class EdgeData <: Serializable<EdgeData> {
    var id: String
    var edge_type: String
    var source: String
    var target: String
    var sourceHandle: Option<String>
    var targetHandle: Option<String>
    var data: HashMap<String, String>
    var label: String
    var sourceX: Float32
    var sourceY: Float32
    var targetX: Float32
    var targetY: Float32

    public init() {
        this.id = ""
        this.edge_type = ""
        this.source = ""
        this.target = ""
        this.sourceHandle = None
        this.targetHandle = None
        this.data = HashMap<String, String>()
        this.label = ""
        this.sourceX = 0.0
        this.sourceY = 0.0
        this.targetX = 0.0
        this.targetY = 0.0
    }

    public init(id: String, edge_type: String, source: String, target: String, sourceHandle: Option<String>, targetHandle: Option<String>, data: HashMap<String, String>, label: String, sourceX: Float32, sourceY: Float32, targetX: Float32, targetY: Float32) {
        this.id = id
        this.edge_type = edge_type
        this.source = source
        this.target = target
        this.sourceHandle = sourceHandle
        this.targetHandle = targetHandle
        this.data = data
        this.label = label
        this.sourceX = sourceX
        this.sourceY = sourceY
        this.targetX = targetX
        this.targetY = targetY
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("id", id))
        dms.add(field<String>("type", edge_type))
        dms.add(field<String>("source", source))
        dms.add(field<String>("target", target))
        dms.add(field<Option<String>>("sourceHandle", sourceHandle))
        dms.add(field<Option<String>>("targetHandle", targetHandle))
        dms.add(field<HashMap<String, String>>("data", data))
        dms.add(field<String>("label", label))
        dms.add(field<Float32>("sourceX", sourceX))
        dms.add(field<Float32>("sourceY", sourceY))
        dms.add(field<Float32>("targetX", targetX))
        dms.add(field<Float32>("targetY", targetY))
        return dms
    }

    public static func deserialize(dm: DataModel): EdgeData {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = EdgeData()
        result.id = String.deserialize(dms.get("id"))
        result.edge_type = String.deserialize(dms.get("type"))
        result.source = String.deserialize(dms.get("source"))
        result.target = String.deserialize(dms.get("target"))
        result.sourceHandle = Option<String>.deserialize(dms.get("sourceHandle"))
        result.targetHandle = Option<String>.deserialize(dms.get("targetHandle"))
        result.data = HashMap<String, String>.deserialize(dms.get("data"))
        result.label = String.deserialize(dms.get("label"))
        result.sourceX = Float32.deserialize(dms.get("sourceX"))
        result.sourceY = Float32.deserialize(dms.get("sourceY"))
        result.targetX = Float32.deserialize(dms.get("targetX"))
        result.targetY = Float32.deserialize(dms.get("targetY"))

        return result
    }
}