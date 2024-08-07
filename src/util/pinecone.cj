package util

from std import collection.*
from std import os.*
from std import os.posix.*
import titoken.*
from net import http.*
from net import tls.*
from serialization import serialization.*
from encoding import json.*
import requests.*


public class Vector <: Serializable<Vector> {
    var id: String
    var values: ArrayList<Float32>

    public init() {
        this.id = ""
        this.values = ArrayList<Float32>()
    }

    public init(id: String, vector: ArrayList<Float32>) {
        this.id = id
        this.values = vector
    }

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(field<String>("id", id))
        dms.add(field<ArrayList<Float32>>("values", values))
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


public class PineCone {
    // Your Pinecone API key
    var api_key = "40075f49-8396-4571-924a-4b6d342cc81d"
    var index_host = "https://canggraph-5e309b3.svc.aped-4627-b74a.pinecone.io"

    public init(){
    }

    public init(api_key: String, index_host: String){
        this.api_key = api_key
        this.index_host = index_host
    }

    public func upsertVectors(sentences: Array<String>, sentence_embeddings: ArrayList<ArrayList<Float32>>) {
        let header: HttpHeaders = HttpHeaders()
        header.add("Api-Key", api_key)

        let client: Requests = Requests()
        let url = "${index_host}/vectors/upsert"
        let body: DataModelStruct = DataModelStruct()

        let vectors: ArrayList<Vector> = ArrayList<Vector>()
        for (index in 0..sentences.size) {
            vectors.append(Vector("id_${index}", sentence_embeddings[index]))
        }

        body.add(field<ArrayList<Vector>>("vectors", vectors))
        body.add(field<String>("namespace", "canggraph"))

        let response = client.post(url, body: body.toJson().toJsonString(), header: header)
        println(response)
    }
}