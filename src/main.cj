import llmapi.*

main() {
  let llm = getLLMInstance(LLMType.OPEN_AI)
  println(llm.query("who are you?"))
  println(llm.query("translate what you have said into Chinese"))
}
