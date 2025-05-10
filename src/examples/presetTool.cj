package canggraph.examples

import canggraph.agent.*
import canggraph.llmapi.*
import canggraph.titoken.*
import canggraph.tool.*
import canggraph.util.*

import std.{collection.*, os.*, os.posix.*}
import encoding.json.*
import serialization.serialization.*

//unavalible
public func presetTool() {
    let google_tool = GoogleSearchRun()
    let result: String = (google_tool.run(["cangjie"]) as String).getOrThrow()
    println("result: ${result}")
}