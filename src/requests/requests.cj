package canggraph.requests

import canggraph.titoken.*

import net.{http.*, tls.*}
import std.{collection.*, os.*}
import serialization.serialization.*
import encoding.json.*
import std.time.Duration

public func getDefaultHeader(): HttpHeaders {
    var defaultHeader: HttpHeaders = HttpHeaders()
    defaultHeader.add("Content-Type", "application/json")
    defaultHeader.add("Accept", "application/json")
    return defaultHeader
}

public class Requests {
    var tlsConfig = TlsClientConfig()
    let client: Client
    var requestBuilder = HttpRequestBuilder()
  
   
    public init() {
        tlsConfig.verifyMode = CertificateVerifyMode.TrustAll
        client = ClientBuilder().tlsConfig(tlsConfig).build()
    }

    public func get(url: String, max_length!: Int64 = 4096, header!: HttpHeaders = getDefaultHeader()): String {  
        let req = requestBuilder
                    .method("GET")
                    .url(url)
                    .addHeaders(header)
                    .build()
        requestBuilder.readTimeout(Duration.minute * 3)
        let rsp = client.send(req)
        let buf = Array<UInt8>(max_length, item: 0)
        let len = rsp.body.read(buf)
        return String.fromUtf8(buf.slice(0, len))
    }

    public func post(url: String, max_length!: Int64 = 32768, header!: HttpHeaders = getDefaultHeader(), body!: String = ""): String {
        // println("url: ${url}")
        let req = requestBuilder
                    .method("POST")
                    .url(url)
                    .addHeaders(header)
                    .body(body)
                    .build()
        let rsp: HttpResponse = client.send(req)
        let buf = Array<UInt8>(10000000, item: 0)
        let len = rsp.body.read(buf)
        let testStr = String.fromUtf8(buf.slice(0, len))
        println(testStr)
        return testStr
    }
}