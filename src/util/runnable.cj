package canggraph.util
import std.collection.*
import encoding.json.*

public interface Runnable {
    func invoke(input: HashMap<String, String>): ResponseMessage
    func invoke(args: JsonObject): ResponseMessage
}