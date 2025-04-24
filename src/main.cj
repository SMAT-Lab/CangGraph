package canggraph

import canggraph.agent.*
import canggraph.llmapi.*
import canggraph.multi.*
import canggraph.examples.*
import canggraph.titoken.*
import canggraph.tool.*
import canggraph.util.*

import std.{fs.*, collection.*, time.*, sync.*, os.*, os.posix.*}
import encoding.json.*
import net.http.*

main() {
    // llmCall()
    // toolCall()
    // agentCall()
    // agentCallWithTool()

    // genCode("我想要写一个归并排序。")
    println(llmPlusRAG())
    var sentences:Array<String> =  ["a = b ++ 1"]
    let embedder = Embedder()
    let sentence_embeddings = embedder(sentences)
    println("embedding: ${sentence_embeddings}")
    
    return 0
}

func genCode(question: String): String {
    let llm = getLLMInstance(LLMType.DeepSeek, model: "deepseek-chat")

    let prompt = """
                You're a code generator.
                Generate Python code according to question.
                Parse the "question" and "answer" and output them in JSON format.

EXAMPLE JSON OUTPUT:
{
    "question": "Which is the highest mountain in the world?",
    "answer": "Mount Everest"
}
                """
    let messages = ArrayList<Message>()
    messages.append(Message("system", prompt))
    messages.append(Message("user", question))

    let answer: String = llm.query(messages.toArray()).getContent()
    println(answer)
    return answer
}