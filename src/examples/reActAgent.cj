package canggraph.examples

import canggraph.agent.*
import canggraph.llmapi.*
import canggraph.titoken.*
import canggraph.tool.*
import canggraph.util.*

import std.{collection.*, os.*, os.posix.*}
import encoding.json.*
import serialization.serialization.*
//unavailable
/*
public func reActAgent(){
    let agent = ReActAgent(ArrayList<Tool>([GoogleSearch(), Calculator()]))

    let response = agent.predict(
        """
        I need to find out who Leo DiCaprio's girlfriend is 
        and then calculate her age raised to the 0.43 power.
        """
        )
    return response
}
*/
