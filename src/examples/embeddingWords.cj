package canggraph.examples

import canggraph.agent.*
import canggraph.llmapi.*
import canggraph.titoken.*
import canggraph.tool.*
import canggraph.util.*

import std.{collection.*, os.*, os.posix.*}
import encoding.json.*
import serialization.serialization.*

public func embeddingWords() {
    var sentences:Array<String> =  ["a = b ++ 1"]
    let embedder = Embedder()
    let sentence_embeddings = embedder(sentences)
    println("size:${sentence_embeddings[0].size}\n-----\nembedding: ${sentence_embeddings}")
    
    return sentence_embeddings
}