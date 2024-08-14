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
import tool.*

main(): Int64 {

    let model: GPTGod = ((getLLMInstance(LLMType.GPTGod)) as GPTGod).getOrThrow()
    let msgs = ArrayList<Message>()
    msgs.append(Message("system", "You are a helpful assistant"))
    // msgs.append(Message("user", "What is the weather like today in New York?"))
    msgs.append(Message("user", "Who you are?"))
    let base_tools = ArrayList<BaseTool>([GetWeather()])
    let tools = ArrayList<Tool>()
    for (tool in base_tools) {
        tools.append(tool.tool)
    }

    let res = model.query(msgs.toArray(), stop: false, tools: tools.toArray() , useTool: false)
    println(res)

    return 0 
}