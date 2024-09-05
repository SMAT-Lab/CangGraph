package graph
from std import collection.*, log.*
from encoding import json.*
import schema.*
import agent.*
import tool.*
import util.*
import chain.*

public class State  {
    // the messages of the graph
    var messages: ArrayList<Message> = ArrayList<Message>()
    // The 'next' field indicates where to route to next
    var next: String = ""
}


public class Edge {
    let start: Node
    let end: Node
    let condition: Bool
    public init(start: Node, end: Node) {
        this.condition = false
        this.start = start
        this.end = end
    }

    public init(start: Node, end: Node, condition: Bool) {
        this.start = start
        this.condition = condition
        this.end = end
    }

    public func printEdge() {
        println("Edge: ${start.nodeName} -> ${end.nodeName}")
    }
}

public class Node {
    let nodeName: String
    let nodeType: String
    var edges: HashMap<String, Edge> = HashMap<String, Edge>()
    var runnable: Option<Runnable> = None

    public init(nodeName: String, nodeType: String) {
        this.nodeName = nodeName
        this.nodeType = nodeType
    }

    public init(nodeName: String, nodeType: String, runnable: Runnable) {
        this.nodeName = nodeName
        this.nodeType = nodeType
        this.runnable = Some(runnable)
    }

    func addEdge(end: Node) {
        let edge: Edge = Edge(this, end)
        edges.put(end.nodeName, edge)
    }

    func addEdge(end: Node, condition: Bool) {
        let edge: Edge = Edge(this, end, condition)
        edges.put(end.nodeName, edge)
    }

    func printEdges() {
        println("Node have the following edges")
        for((k, v) in edges) {
            v.printEdge()
        }
    }

    func getOnlyEdge(): Edge {
        if (edges.size != 1) {
            println("Node ${nodeName} has more than one edge")
            return Edge(this, this)
        }
        for ((k, v) in edges) {
            return v
        }
        Edge(this, this)
    }

    func hasEdge(): Bool {
        return edges.size > 0
    }

    public operator func !=(other: Node): Bool {
        return this.nodeName != other.nodeName
    }

    public operator func ==(other: Node): Bool {
        return this.nodeName == other.nodeName
    }

    public func run(input: Dict): ResponseMessage {
        match (runnable) {
            case None => return ResponseMessage()
            case Some(node) => 
                if (node is CoTChain) {
                    return (node as CoTChain).getOrThrow().invoke(input)
                } else if (node is BaseTool) {
                    return (node as BaseTool).getOrThrow().invoke(input)
                } else if (node is create_openai_tools_agent) {
                    return (node as create_openai_tools_agent).getOrThrow().invoke(input)
                } 
                else {
                    return ResponseMessage()
                }
        }
    }
}


public class Graph {
    private var nodes: HashMap<String, Node> = HashMap<String, Node>()
    private var state: State = State()
    let logger: SimpleLogger = SimpleLogger()
    let startNode = Node(START, START)
    let endNode = Node(END, END)
    public init() {
        nodes.put(START, startNode)
        nodes.put(END, endNode)

        let systemMessage = Message("system", "You are a helpful assistant!")
        state.messages.append(systemMessage)
    }

    private func checkNode(node: Node): Bool {
        // check if the node exists in the graph
        return nodes.contains(node.nodeName)
    }

    public func addNode(node: Node)  {
        if (node.nodeName == END || node.nodeName == START) {
            logger.log(LogLevel.ERROR, "Node ${node.nodeName} is a reserved node name")
            return
        }
        if (!checkNode(node)) {
            this.nodes.put(node.nodeName, node)
        }
    }

    public func getNode(nodeName: String): Node {
        return this.nodes[nodeName]
    }

    private func checkEdge(start: String, ends: HashSet<String>): Bool {
        if (start == END) {
            logger.log(LogLevel.ERROR, "END cannot be a start node")
            return false
        }
        if (start == START || ends.contains(START)) {
            logger.log(LogLevel.ERROR, "START cannot be used to construct edges")
            return false
        }
        return true
    }

    public func addEdge(start: Node, end: Node) {
        // add an edge from start to end， 但是由于该边不是conditional的，所以start节点只允许有一个边
        if (start.hasEdge()) {
            logger.log(LogLevel.ERROR, "Node ${start.nodeName} already has an edge")
            return
        }

        if (checkNode(start) && checkNode(end)) {
            let startNode = this.nodes.get(start.nodeName).getOrThrow()
            startNode.addEdge(end)
        }
    }

    public func addConditionalEdge(start: Node, end: Node) {
        var checkStart: String = start.nodeName
        var checkEnds: HashSet<String> = HashSet<String>()
        if (checkNode(end)) {
            checkEnds.put(end.nodeName)
            if(this.checkEdge(checkStart, checkEnds)) {
                let startNode = this.nodes.get(start.nodeName).getOrThrow()
                startNode.addEdge(end)
            }
        }
    }

    public func setEntryPoint(node: Node) {
        if(checkNode(node)) {
            startNode.addEdge(node)
            state.next = node.nodeName
        }
    }

    public func setExitPoint(node: Node) {
        if(checkNode(node)) {
            node.addEdge(endNode)
        }
    }

    public func invoke(input: Dict) {
        var nowNode: Node = startNode
        let prompt = input["text"]
        let message = Message("user", prompt)
        state.messages.append(message)
        
        var nowInPut: String = prompt
        while(nowNode != endNode){
            println("nowNode: ${nowNode.nodeName}")
            // nowNode.printEdges()
            if (nowNode == startNode) {
                nowNode = nowNode.edges.get(state.next).getOrThrow().end
                continue
            }
            let input = Dict()
            input["text"] = nowInPut
            input["messages"] = state.messages.serialize().toJson().toString()
            let res: ResponseMessage = nowNode.runnable.getOrThrow().invoke(input)

            let obj: JsonObject = (res.serialize().toJson() as JsonObject).getOrThrow()
            
            if (((obj.get("tool_call").getOrThrow()) as JsonBool).getOrThrow().getValue()) {
                let toolCalls = (obj.get("tool_calls").getOrThrow() as JsonArray).getOrThrow()
                for (i in 0..toolCalls.size()) {
                    let toolCall = (toolCalls.get(i).getOrThrow() as JsonObject).getOrThrow()
                    let toolName = toolCall.get("name").getOrThrow().asString().getValue()
                    let toolInput = toolCall.get("arguments").getOrThrow().asObject()
                    let tool_ids: String = toolCall.get("id").getOrThrow().asString().getValue()
                    // println(toolName)
                    match(toolName) {
                        case "RouteDecider" => 
                            let next = RouteDecider().selectNext(toolInput)
                            // println(next)
                            state.next = next
                        case _ =>
                            // println(toolName)
                            let toolCallMessage = ToolCallMessage(tool_ids, FunctionInfo(toolName, ""), "function")
                            let toolMessage = Message("assistant")
                            toolMessage.add_tool_calls(toolCallMessage)
                            state.messages.append(toolMessage)

                            let tool = nodes.get(toolName).getOrThrow()
                            let toolRes = (tool.runnable.getOrThrow() as BaseTool).getOrThrow().invoke(toolInput)
                            let obs: String = (toolRes.serialize().toJson() as JsonObject).getOrThrow()["content"].asString().getValue()
                            let resultMessage = Message("tool", obs)
                            resultMessage.set_tool_call_id(tool_ids)
                            state.messages.append(resultMessage)
                    }
                }
            } else {
                let content = obj.get("content").getOrThrow().asString().getValue()
                state.next = nowNode.getOnlyEdge().end.nodeName
                state.messages.append(Message("assistant", content))
            }

            if  (state.next == "FINISH") {
                break
            }
            nowNode = nowNode.edges.get(state.next).getOrThrow().end
        }
        return state.messages.serialize().toJson()
    }
}