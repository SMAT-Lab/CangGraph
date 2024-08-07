package requests

from std import collection.*
from std import os.*
from std import os.posix.*
import titoken.*
from net import http.*
from net import tls.*
from serialization import serialization.*
from encoding import json.*

public func getDefaultHeader(): HttpHeaders {
    var defaultHeader: HttpHeaders = HttpHeaders()
    defaultHeader.add("Content-Type", "application/json")
    defaultHeader.add("Accept", "application/json")
    return defaultHeader
}


public class Requests {
    let client: Client = ClientBuilder().tlsConfig(TlsClientConfig()).build() 
    var requestBuilder = HttpRequestBuilder()
    public init() {

    }

    public func get(url: String, max_length!: Int64 = 1024, header!: HttpHeaders = getDefaultHeader()): String {  
        let req = requestBuilder
                    .method("GET")
                    .url(url)
                    .addHeaders(header)
                    .build()
        
        let rsp = client.send(req)
        let buf = Array<UInt8>(max_length, item: 0)
        let len = rsp.body.read(buf)
        return String.fromUtf8(buf.slice(0, len))
    }

    public func post(url: String, max_length!: Int64 = 1024, header!: HttpHeaders = getDefaultHeader(), body!: String = ""): String {
        // println("url: ${url}")
        let req = requestBuilder
                    .method("POST")
                    .url(url)
                    .addHeaders(header)
                    .body(body)
                    .build()
        let rsp = client.send(req)
        let buf = Array<UInt8>(max_length, item: 0)
        let len = rsp.body.read(buf)
        return String.fromUtf8(buf.slice(0, len))
    }
}