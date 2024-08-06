// from net import http.*

// main () {

// }

from std import collection.*
from std import os.*
from std import os.posix.*
import titoken.*
from net import http.*
from net import tls.*
from serialization import serialization.*
from encoding import json.*

public func serialize(api_key: String): DataModel {
    let dms = DataModelStruct()
    dms.add(field<String>("Api-Key", api_key))
    return dms
}

main(): Int64 {
    var sentences:Array<String> =  ["苍穹是什么"]
    //分词
    let tokenizer = Tokenizer(tokensFilePath: getcwd()+"/resource/tokenizer.json")
    let embedder = Embedder(modelPath: getcwd()+"/resource/embedding_model.onnx", tokensFilePath:getcwd()+"/resource/tokenizer.json")
    println("tokens: ${tokenizer(sentences)}")
    //计算词嵌入向量
    let sentence_embeddings = embedder(sentences)
    println("embedding: ${sentence_embeddings[0].size}")

    // Your Pinecone API key
    let api_key = "40075f49-8396-4571-924a-4b6d342cc81d"

        // 1. 构建 client 实例
    let client: Client = ClientBuilder().tlsConfig(TlsClientConfig()).build()
    var requestBuilder = HttpRequestBuilder()
    let req = requestBuilder
                   .method("GET")
                   .url("https://api.pinecone.io/indexes/canggraph")
                   .header("Api-Key",api_key)
                   .build()
    let body = serialize(api_key)
    println(body.toJson())
    // 2. 发送 request
    let rsp = client.send(req)
    // 3. 读取response
    let buf = Array<UInt8>(1024, item: 0)
    let len = rsp.body.read(buf)
    println(String.fromUtf8(buf.slice(0, len)))
    // 4. 关闭连接
    client.close()

    return 0 
}



