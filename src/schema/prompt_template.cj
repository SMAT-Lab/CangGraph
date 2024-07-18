package schema

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