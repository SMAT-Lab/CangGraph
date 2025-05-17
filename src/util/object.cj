package canggraph.util

import encoding.json.*
import std.collection.*

public func string2JsonObject(response: String):JsonObject{
    let data: JsonObject
    try {
        data = JsonValue.fromStr(response).asObject()
    } catch (e: JsonException) {
        println(response)
        throw e
    }
    return data
}

public func map2JsonObject(map: HashMap<String, String>): JsonObject {
    let jsonMap: JsonObject = JsonObject()
    for ((k, v) in map) {
        jsonMap.put(k, JsonString(v))
    }
    return jsonMap
}

public func parseString(raw_json: String): String {
    var str = raw_json[1..raw_json.size-1]
    str = str.replace("\\n", "\n")
    str = str.replace("\\t", "\t")
    str = str.replace("\\\"", "\"")
    return str
}