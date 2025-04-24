package canggraph.examples

import canggraph.agent.*
import canggraph.llmapi.*
import canggraph.titoken.*
import canggraph.tool.*
import canggraph.util.*

import std.{collection.*, os.*, os.posix.*}
import encoding.json.*
import serialization.serialization.*

public func llmPlusRAG() {
    let pineCone = PineCone()
    // let path: String = getcwd()
    // let objs = read_from_csv("${path}/data/bugfixes_test_top5.csv")
    // for (i in 0..5) {
    //     println("${i}: ${objs[i]}")
    // }
    // return 0

    var sentences:Array<String> =  ["a = b ++ 1"]
    let embedder = Embedder()
    // let sentence_embeddings = embedder(sentences)
    // println("embedding: ${sentence_embeddings}")
    
    // let row = objs[4].asObject().get("values").getOrThrow().asArray()
    // let query_rule: String = row[0].asString().getValue()
    // println(query_rule)
    // let query_description = row[1].asString().getValue()
    // let query_buggy_code = row[2].asString().getValue()
    // println(query_buggy_code)
    let res = pineCone.query(sentences[0])
    return res
    // let similars = res["matches"].asArray()
    // var prompt = "我将给出你若干个与问题代码类型相同，问题代码类似的例子，包括缺陷规则、缺陷描述、缺陷代码、缺陷解释以及修复代码\n"
    // for (index in 0..similars.size()) {
    //     let item = similars[index].asObject()["metadata"].asObject()
    //     let rule = item["rule"].asString().getValue()
    //     let description = item["description"].asString().getValue()
    //     let buggy_code = item["buggy_code"].asString().getValue()
    //     let buggy_explanation = item["buggy_explanation"].asString().getValue()
    //     let fixed_code = item["fixed_code"].asString().getValue()

    //     prompt = prompt + "Demo: ${index}\nRule: ${rule}\nDescription: ${description}\nBuggy Code: \n${buggy_code}\nBuggy Explanation: ${buggy_explanation}\nFixed Code:\n${fixed_code}\n"
    // }
    // prompt = prompt + "现在，请根据上面的例子，来修复我的问题代码:\n${query_buggy_code}\n\n对应的问题类型是: ${query_rule}\n该问题类型的描述如下:${query_description}\n请您帮我修复一下: \n```arkts\n"
    // //prompt =  "请修复我的问题代码:\n```arkts\n${query_buggy_code}\n```\n\n请您帮我修复一下: \n```arkts\n"
    // println(prompt)
    // let llm = getLLMInstance(LLMType.DeepSeek, model: "arktsLLM")
    // let msgs: ArrayList<Message> = ArrayList<Message>()
    // let sys_msg = Message("system", "You are a helpful assistant!")
    // let msg = Message("user", prompt)
    // msgs.append(sys_msg)
    // msgs.append(msg)

    // let response = llm.query(msgs.toArray()).getContent()
    // println(response)

    // return 0
}