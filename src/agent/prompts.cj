package canggraph.agent

import std.{unittest.*, collection.*, fs.*}

public var selfDifinedPrompts: HashMap<String, String> = HashMap<String, String>(
    [
        (
            "assistant", 
            """
            You are a helpful assistant that helps a support agent with answering programming questions.
            If you don't know the answer, just say that you don't know, you must not make up an answer.
            """
        ),
        (
            "test",
            "你无法直接执行行动，但是可以根据我给你的节点选择下一步的动作节点。"
        ),
        (
            "calculater",
            """
            你是一个计算器，你只有计算功能，如果有其他任务请求，请直接拒绝，输出“我只会计算”。
            """
        )
    ]
)

public func addPrompt(name: String, newPrompt: String) {
    if(selfDifinedPrompts.contains(name)) {
        return false
    }

    selfDifinedPrompts.put(name, newPrompt)

    return true
}

public func showPromptList() {
    var promptList: HashSet<String> = HashSet<String>()
    
    for ((k, v) in selfDifinedPrompts) {
        promptList.put(k)
    }

    return promptList
}

public func getPromptFromFile(path: String) {
    return String.fromUtf8(File.readFrom(path))
}