package canggraph.chain

import canggraph.schema.*
import canggraph.util.{Message, ResponseMessage, Runnable, string2JsonObject, map2JsonObject}

import std.collection.*
import encoding.json.*

public class SequentialChain {
    private var memory = Dict()
    let chains: Array<SimpleChain>
    // let chainVars = HashSet<String>()

    public init(inputChains: Array<SimpleChain>, inputVars: HashSet<String>, outputVars: HashSet<String>) {
        this.chains = inputChains
        for (str in inputVars) {
            memory.put(str, "")
        }
        for (str in outputVars) {
            memory.put(str, "")
        }
    }

    public func invokeChain(inputData: Dict) {
        for ((k, v) in inputData) {
            if (memory.contains(k)) {
                memory.put(k, v)
            }
        }
        for (chain in chains) {
            let inputList = chain.getInputList()
            let inputVars = Dict()
            for (par in inputList) {
                inputVars.put(par, memory[par])
            }
            let response: HashMap<String, String> = chain.invoke(inputVars)
            let jsonResponse = map2JsonObject(response)

            let outputList = chain.getOutputList()
            for (output in outputList) {
                memory.put(output, jsonResponse.get(output).getOrThrow().toString())
            }
        }

        println(memory)
        return memory
    }
}