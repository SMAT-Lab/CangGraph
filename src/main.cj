from std import collection.*
from std import os.*
from std import os.posix.*
import titoken.*

main(): Int64 {
    var sentences:Array<String> =  ["苍穹是什么","苍穹"]
    //分词
    let tokenizer = Tokenizer(tokensFilePath: getcwd()+"/resource/tokenizer.json")
    let embedder = Embedder(modelPath: getcwd()+"/resource/embedding_model.onnx", tokensFilePath:getcwd()+"/resource/tokenizer.json")
    println("tokens: ${tokenizer(sentences)}")
    //计算词嵌入向量
    let sentence_embeddings = embedder(sentences)
    println("embedding: ${sentence_embeddings}")
    return 0 
}
