package canggraph.chain

import canggraph.schema.*

import std.collection.*

public abstract class Chain <: Runnable {
    let memory = None<BaseMemory> 

    public open func preprocess(input:Dict): Dict {
        let newInput = match(memory) {
            case Some(m) => m.loadMemoryVariable(input)
            case None => input
        }
        return newInput
    }

    public open func postprocess(output: Dict): Dict {
        memory?.saveContext(output)
        return output
    }

    public func invoke(input: JsonObject): ResponseMessage

    public func invoke(input: Dict): ResponseMessage

    public func invoke(input: Dict, messages: ArrayList<Message>): ResponseMessage

}
