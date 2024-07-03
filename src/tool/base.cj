package tool
from encoding import json.*
public interface Runnable {

    func run(args : Array<Any>) : Any

    func run(query : String) : String

    func run(args: JsonObject): String

}

/** 
 the super class of the tools
*/
public abstract class BaseTool <: Runnable {


    // the name of the tool
    public var name : String

    // the description of the tool
    public var description : String

    public var args_schema: Option<JsonValue> = None
    

    // contruction
    public init() {
        this.name = ""
        this.description = ""
    }

    // contruction with name and description
    public init(_name : String, _description : String) {
        this.name = _name
        this.description = _description
    }

    public func setArgs(args_schema: JsonValue) {
        this.args_schema = args_schema
    }

}