package chain
from std import collection.*

import schema.*

public abstract class Chain {
    let memory = None<BaseMemory> 
    public open func generate(inputs: Collection<Dict>): Collection<Dict>

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
    

    public func predict(input: Dict): Dict {
        let preparedInput = preprocess(input)
        let output = generate(ArrayList([preparedInput])).iterator().next().getOrThrow({ => Exception("No output in Chain predicting!")})
        return postprocess(output)
    }

    public func predict(inputs: String): Dict {
        let preparedInput = preprocess(HashMap([("text", inputs)]))
        let output = generate(ArrayList([preparedInput])).iterator().next().getOrThrow({ => Exception("No output in Chain predicting!")})
        return postprocess(output)
    }

    public func run(inputs: String): Dict {
        // println("query: ${inputs}")
        let preparedInput = preprocess(HashMap([("text", inputs)]))
        let output = generate(ArrayList([preparedInput])).iterator().next().getOrThrow({ => Exception("No output in Chain predicting!")})
        return postprocess(output)
    }
    public func apply(inputs: Collection<Dict>): Collection<Dict> {
        let preparedInputs = collectArrayList(map(preprocess)(inputs))
        let output = generate(preparedInputs)
        return collectArrayList(map(postprocess)(output))
    }   

    public func apply(inputs: Collection<String>): Collection<Dict> {
        let preparedInputs = collectArrayList(map({input:String => HashMap([("text", input)])} ~> preprocess)(inputs))
        let output = generate(preparedInputs)
        return collectArrayList(map(postprocess)(output))
    }
}
