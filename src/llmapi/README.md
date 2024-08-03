
# 源码目录
```
├── README.md
├── api_request.cj
├── openai.cj
└── model_factory.cj
```

# 接口说明
## 文件：api_request.cj
1. send_llm_request：
    1. 向LLM发送https请求的接口
    2. 参数：  
    (authHeader:HashMap<String, String>, url:String, postData:String, bufferSize!:Int64=4096)
    - authHeader:HashMap<String, String>：LLMs API的授权，如“Authorization: Bearer $OPENAI_API_KEY”。  
    - url:String：调用API的URL，如“https://api.openai.com/v1/chat/completions”。  
    - postData:String: Json格式的请求正文，如:
```
    '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Hello!"}]
    }'
```

## 文件：model_factory.cj
1. LLMType
枚举类型，保存当前支持的LLM类型。
```
public enum LLMType {
    | OPEN_AI
    | AZURE_OPEN_AI
}  
```


2. getLLMInstance
用于创建指定类型的LLM的实例。当前仅支持OpenAI。

3. LargeModel
所有LLM模型的基类。新添加的模型需实现该抽象类。
```
public abstract class LargeModel {
    /*
    创建抽象类LargeModel
    */
    public open func query(content: String): String
    /*
    定义query函数与LLM进行交流，参数content（请求正文）类型String，返回值类型String
    */
}
```

# openai.cj

函数：public func query(content: String): String  
功能：向LLM API发送聊天请求, 返回大模型性的响应。  
参数：content，需要发送的聊天内容。

函数：public func embedding(content: String,model!:String="text-embedding-ada-002")
功能：调用LLM API对目标内容进行embedding。  
参数：content，需要进行embedding的内容。
参数：model，进行embedding的模型名称。

# 使用说明
## 编译

```
mkdir ../../libs  --> 在目录../../下创建libs文件夹  
export CANGJIE_PATH=../../libs/  -->  设置cangjie运行环境  
cjc -p ../../src/llmapi --output-type=staticlib -o ../../libs/ && cjc testcase0001.cj ../../libs/libllmapi.a && ./main
```

## LLM调用示例
调用chatGPT（假设以下文件保存于“testcase0001.cj”）
```
import llmapi.*
main() {
 let llm = getLLMInstance(LLMType.AZURE_OPEN_AI)
 println(llm.query("who are you?"))
 println(llm.query("translate what you have said into Chinese"))
}
```
编译及运行
```

cjc testcase0001.cj ../../libs/libllmapi.a  -L ../../libs -l api_request
./main
```
期待输出
```
I am an AI language model created by OpenAI. My purpose is to assist and communicate with people in a human-like manner.
我是由OpenAI创建的AI语言模型。我的目的是以类似人类的方式协助和与人交流。
```