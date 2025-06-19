package canggraph

import canggraph.agent.*
import canggraph.chain.*
import canggraph.llmapi.*
import canggraph.multi.*
import canggraph.examples.*
import canggraph.schema.*
import canggraph.titoken.*
import canggraph.tool.*
import canggraph.util.*

import std.{fs.*, collection.*, time.*, sync.*, os.*, os.posix.*}
import encoding.json.*
import net.http.*

main() {
    println("--------\nLLMCall\n--------")
    llmCall()
    println("--------\nAgentCall\n--------")
    agentCall("Here is the formula: `3x + 2 = 0`")
    println("--------\nAgentCall--Tool\n--------")
    agentCallWithTool()
    println("--------\nChainCall\n--------")
    chainCall()
    println("--------\nRAG\n--------")
    llmPlusRAG()
    println("--------\nembedding\n--------")
    embeddingWords()
    
    return 0
}