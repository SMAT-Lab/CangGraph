from std import collection.*
from std import os.*
from std import os.posix.*
import titoken.*
from net import http.*
from net import tls.*
from serialization import serialization.*
from encoding import json.*
import requests.*
import llmapi.*
import util.*

main(): Int64 {

    let pineCone = PineCone()
    // 往向量数据库中添加数据
    let path: String = getcwd()
    // let objs = read_from_csv("${path}/data/demo.csv", header: true)
    // let vectors: ArrayList<Vector> = pineCone.get_vectors(objs)
    // pineCone.upsertVectors(vectors)
    // 查询向量数据库
    let objs = read_from_csv("${path}/data/test.csv", header: true)
    let row = objs[1].asObject().get("values").getOrThrow().asArray()
    let query_rule = row[0].toString()
    let query_description = row[1].toString()
    let query_buggy_code = row[2].toString()
    let res: JsonObject = pineCone.query(query_buggy_code, rule: query_rule)
    let similars = res["matches"].asArray()
    var prompt = "我将给出你若干个与问题代码类型相同，问题代码类似的例子，包括缺陷规则、缺陷描述、缺陷代码、缺陷解释以及修复代码\n"
    for (index in 0..similars.size()) {
        let item = similars[index].asObject()["metadata"].asObject()
        let rule = item["rule"].asString().getValue()
        let description = item["description"].asString().getValue()
        let buggy_code = item["buggy_code"].asString().getValue()
        let buggy_explanation = item["buggy_explanation"].asString().getValue()
        let fixed_code = item["fixed_code"].asString().getValue()

        prompt = prompt + "Demo: ${index}\nRule: ${rule}\nDescription: ${description}\nBuggy Code: ${buggy_code}\nBuggy Explanation: ${buggy_explanation}\nFixed Code: ${fixed_code}\n"
    }
    prompt = prompt + "现在，请根据上面的例子，来修复我的问题代码:\n${query_buggy_code}\n\n对应的问题类型是: ${query_rule}\n该问题类型的描述如下:${query_description}\n请您帮我修复一下: \n```arkts\n"
    // println(prompt)
    let llm: Ollama = (getLLMInstance(LLMType.OLLAMA, model: "arktsLLM") as Ollama).getOrThrow()
    let msgs: ArrayList<Message> = ArrayList<Message>()
    let sys_msg = Message("system", "You are a helpful assistant!")
    let msg = Message("user", prompt)
    msgs.append(sys_msg)
    msgs.append(msg)

    let response = llm.query(msgs)
    println(response)

    return 0 
}

