package canggraph.util

import canggraph.titoken.*
import canggraph.requests.Requests

import net.{http.*, tls.*}
import std.{collection.*, os.*, os.posix.*}
import serialization.serialization.*
import encoding.json.*

public class Vector <: Serializable<Vector> {
    var id: String
    var values: ArrayList<Float32>
    var metadata: HashMap<String, String>

    public init() {
        this.id = ""
        this.values = ArrayList<Float32>()
        this.metadata = HashMap<String, String>()
    }

    public init(id: String, vector: ArrayList<Float32>) {
        this.id = id
        this.values = vector
        this.metadata = HashMap<String, String>()
    }

    public init(id: String, vector: ArrayList<Float32>, metadata: HashMap<String, String>) {
        this.id = id
        this.values = vector
        this.metadata = metadata
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("id", id))
        dms.add(field<ArrayList<Float32>>("values", values))
        dms.add(field<HashMap<String, String>>("metadata", metadata))
        return dms
    }

    public static func deserialize(dm: DataModel): Vector {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = Vector()
        result.id = String.deserialize(dms.get("id"))
        result.values = ArrayList<Float32>.deserialize(dms.get("values"))

        return result
    }
}

public class Filter <: Serializable<Filter> {
    var rule: String

    public init() {
        this.rule = ""
    }

    public init(rule: String) {
        this.rule = rule
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("rule", rule))
        return dms
    }

    public static func deserialize(dm: DataModel): Filter {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = Filter()
        result.rule = String.deserialize(dms.get("rule"))

        return result
    }   
}

// 
// "options": {
//     "num_ctx": 4096
// }
public func getEmbedding(sentence: String): JsonArray {
    let url = "http://localhost:11434/api/embeddings"
    // let header: HttpHeaders = HttpHeaders()
    // header.add("Content-Type", "application/json")
    let body: DataModelStruct = DataModelStruct()
    body.add(field<String>("model", "shaw/dmeta-embedding-zh"))
    body.add(field<String>("prompt", sentence))

    let client = Requests()
    let response = string2JsonObject(client.post(url, body: body.toJson().toJsonString()))

    return response["embeddings"].asArray()
}


public class PineCone {
    // Your Pinecone API key
    var api_key: String
    var index_host: String
    var namespace: String = "canggraph"

    //分词
    let tokenizer = Tokenizer(tokensFilePath: getcwd()+"/resource/tokenizer.json")
    let embedder = Embedder(modelPath: getcwd()+"/resource/embedding_model.onnx", tokensFilePath:getcwd()+"/resource/tokenizer.json")

    public init(api_key!: String = "40075f49-8396-4571-924a-4b6d342cc81d", index_host!: String = "https://canggraph-5e309b3.svc.aped-4627-b74a.pinecone.io", namespace!: String = "canggraph") {
        this.api_key = api_key
        this.index_host = index_host
        this.namespace = namespace
    }

    public func upsertVectors(vectors: ArrayList<Vector>) {
        let header: HttpHeaders = HttpHeaders()
        header.add("Api-Key", api_key)

        let client: Requests = Requests()
        let url = "${index_host}/vectors/upsert"
        let body: DataModelStruct = DataModelStruct()

        body.add(field<ArrayList<Vector>>("vectors", vectors))
        body.add(field<String>("namespace", namespace))

        client.post(url, body: body.toJson().toJsonString(), header: header)
    }

    public func query(query: String, rule!: Option<String> = None, top_k!: Int64 = 3) {
        let header: HttpHeaders = HttpHeaders()
        header.add("Api-Key", api_key)
        header.add("Content-Type", "application/json")

        let client: Requests = Requests()
        let url = "${index_host}/query"
        let body: DataModelStruct = DataModelStruct()

        let vector: ArrayList<Float32> = embedder(query)[0]
        body.add(field<ArrayList<Float32>>("vector", vector))
        body.add(field<Int64>("top_k", top_k))
        body.add(field<String>("namespace", namespace))
        body.add(field<Bool>("include_metadata", true))

        if (rule.isSome()) {
            // filter={"rule": test[i]["rule"]}
            let filter = Filter(rule.getOrThrow())
            body.add(field<Filter>("filter", filter))
        }

        let response = client.post(url, body: body.toJson().toJsonString(), header: header)
        println(response)
        let res_obj = JsonValue.fromStr(response).asObject()
        return res_obj
    }

    public func get_vector(id: String, obj: JsonObject, embedding!: Option<ArrayList<Float32>> = None): Vector {
        let row = obj.get("values").getOrThrow().asArray()
        let rule = row[0].asString().getValue()
        let description = row[1].asString().getValue()
        let buggy_code = row[2].asString().getValue()
        let buggy_explanation = row[3].asString().getValue()
        let fixed_code = row[4].asString().getValue()

        var sentence_embedding: ArrayList<Float32> = ArrayList<Float32>()
        if (embedding.isSome()) {
            sentence_embedding = embedding.getOrThrow()
        }
        else {
            sentence_embedding = embedder([buggy_code])[0]
        }

        var vector = Vector(id, sentence_embedding)
        vector.metadata.put("rule", rule)
        vector.metadata.put("description", description)
        vector.metadata.put("buggy_code", buggy_code)
        vector.metadata.put("buggy_explanation", buggy_explanation)
        vector.metadata.put("fixed_code", fixed_code)

        return vector
    }

    public func get_vectors(objs: ArrayList<JsonValue>): ArrayList<Vector> {
        var vectors = ArrayList<Vector>()
        var sentences = Array<String>(objs.size, item: "")
        for (i in 0..objs.size) {
            let obj = objs[i].asObject()
            sentences[i] = obj.get("values").getOrThrow().asArray()[2].toString()
        }
        // let sentence_embeddings = embedder(sentences)

        for (i in 0..objs.size) {
            if(i==4 || i == 8 || i == 9) {
                continue
            }
            if (i<10) {
                continue
            }
            println("Processing ${i}")
            let obj = objs[i].asObject()
            // let vector: Vector = get_vector(i.toString(), obj, embedding: sentence_embeddings[i])
            let vector: Vector = get_vector(i.toString(), obj)
            vectors.append(vector)
        }
        return vectors
    }
}