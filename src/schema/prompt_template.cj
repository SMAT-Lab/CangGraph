package canggraph.schema

import encoding.json.*
import std.collection.*

public abstract class PromptTemplate {
    public open func format(input: Dict): String
}

public class SelfDefinePromptTemplate <: PromptTemplate {
    public override func format(input: Dict): String {
        let PREFIX = """
            ${input["system_message"]}
        """

        let SUFFIX = """
            ${input["user_message"]}
        """
        /* multi-role support */
        let system_prompt =  PREFIX + "\n"
        let user_prompt = SUFFIX
        let prompt_obj = JsonObject()
        prompt_obj.put("system", JsonString(system_prompt))
        prompt_obj.put("user", JsonString(user_prompt))
        return prompt_obj.toString()
    }
}

public class LLMPromptTemplate {
    let varsList: Array<String>
    let template: String

    public init(varsList: Array<String>, template: String) {
        if (template.size < 1) {
            throw Exception("Empty template not allowed.")
        }

        for (str in varsList) {
            let aimStr = "{" + str + "}"

            if (!template.contains(aimStr)) {
                throw Exception("Placeholder not set: ${str}")
            }
        }

        this.varsList = varsList
        this.template = template
    }

    public func getVarList() {
        return this.varsList
    }

    public func format(inputVars: HashMap<String, String>): String {
        var promptText: String = template

        for (str in varsList) {
            if (!inputVars.contains(str)) {
                throw Exception("Missing value for input variable: ${str}")
            }

            let aimStr = "{" + str + "}"
            // println(aimStr)
            // println(inputVars[str])
            promptText = promptText.replace(aimStr, inputVars[str])
            // println(promptText)
        }

        return promptText
    }
}
    // let prompt = LLMPromptTemplate(
    //     ["context", "question"],
    //     "你是一位智能助手，根据以下背景信息回答问题：{context}。问题是：{question}。"
    // )

    // println(prompt.format(Dict([
    //     ("context", "CangChain 是一个用于快速构建语言模型应用的框架。它提供了丰富的工具和模块来创建和部署各种应用。"),
    //     ("question", "CangChain 是什么？")
    // ])))