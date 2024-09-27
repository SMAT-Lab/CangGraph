package util

public interface Runnable {
    func invoke(input: HashMap<String, String>): ResponseMessage
    func invoke(args: JsonObject): ResponseMessage
}