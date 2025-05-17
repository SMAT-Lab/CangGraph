package canggraph.chain

import canggraph.llmapi.*
import canggraph.schema.*
import canggraph.util.*

import std.collection.*
import encoding.json.*

public class SimpleQAPromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        return "You're a helpful assistant.\n\nQuestion: " + input["question"] + "\n\nAnswer: "
    }
}

public class SimpleQAChain <: LLMChain {
    public init() {
        super(getLLMInstance(LLMType.DeepSeek, model:"deepseek-chat"), SimpleQAPromptTemplate())
    }
}

public class SimpleChain {
    let llm: LargeModel
    let template: LLMPromptTemplate

    let outputVars: HashSet<String>
    var output: Dict = Dict()

    public init(llm: LargeModel, template: LLMPromptTemplate, outputList: HashSet<String>) {
        llm.chainLLM()
        this.llm = llm
        this.template = template
        this.outputVars = outputList

        for (str in outputList) {
            output.put(str, "")
        }
    }

    public func invoke(inputVars: Dict) {
        let parsSet = outputVars.toArray().toString()

        let prompt = """
                The user will provide some requests. Please parse ${parsSet} and output them in JSON format.
                """
        
        let messages = ArrayList<Message>()
        messages.append(Message("system", prompt))
        messages.append(Message("user", template.format(inputVars)))

        let response =  llm.query(messages.toArray()).getContent()
        let jsonResponse = string2JsonObject(response)
        var result = Dict()
        for (output in outputVars) {
            result.put(output, jsonResponse.get(output).getOrThrow().toString())
        }
        // println("response:")
        // println(response)
        println("-----\nresult:")
        println(result)
        return result
    }

    public func getInputList() {
        return this.template.getVarList()
    }

    public func getOutputList() {
        return this.outputVars
    }
}