package canggraph.chain

import canggraph.schema.*
import canggraph.util.{Message, ResponseMessage, Runnable, string2JsonObject, map2JsonObject}

import std.collection.*
import encoding.json.*

public class RouterChain {
    private var memory = Dict()
    // let chains: HashSet<SimpleChain>
    let destinationChains: HashMap<String, SimpleChain>
    var defaultChain: SimpleChain

    public init(destinationChains: HashMap<String, SimpleChain>, defaultChain: SimpleChain) {
        this.destinationChains = destinationChains
        this.defaultChain = defaultChain
        // for ((k, v) in destinationChains)
    }

    // private func route()
}