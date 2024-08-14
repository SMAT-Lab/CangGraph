package util
from serialization import serialization.*
from encoding import json.*

public class Message <: Serializable<Message> {
    var role: String
    var content: String

    public init() {
        this.role = ""
        this.content = ""
    }

    public init(role: String, content: String) {
        this.role = role
        this.content = content
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("role", role))
        dms.add(field<String>("content", content))
        return dms
    }

    public static func deserialize(dm: DataModel): Message {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = Message()
        result.role = String.deserialize(dms.get("role"))
        result.content = String.deserialize(dms.get("content"))

        return result
    }
}
