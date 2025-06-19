package canggraph.examples

import canggraph.agent.*
import canggraph.llmapi.*
import canggraph.titoken.*
import canggraph.tool.*
import canggraph.util.*

import std.{collection.*, os.*, os.posix.*, fs.*}
import encoding.json.*
import serialization.serialization.*

public func llmPlusRAG() {
    let code = String.fromUtf8(File.readFrom("/home/CangGraph/src/examples/RAGcode.txt"))
    println(JsonString(code))
    var codes:Array<String> =  [code]
    let embedder = Embedder()
    let code_embeddings = embedder(codes)
    let result = vectorSearch(code_embeddings[0])

    let matches = result["data"].asObject()["matches"].asArray()
    let metadata = matches[0].asObject()["metadata"]

    println(metadata)

    let llm = getLLMInstance(LLMType.DeepSeek, model: "deepseek-chat")

    let prompt = """
                You're a code-defect detector.
                I'll give you a piece of code with possible bugs and some similar buggy codes.
                Tell me whether the code is correct. If not, point bugs.
                """
    let messages = ArrayList<Message>()
    messages.append(Message("system", prompt))
    messages.append(Message("user", "Code piece: ${codes[0]}\nSimilar buggy codes: ${metadata.toString()}"))

    println(llm.query(messages.toArray()).getContent())
    return 0
}