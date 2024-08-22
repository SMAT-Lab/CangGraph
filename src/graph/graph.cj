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
        println("Edges:")
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

    public func addConditionalEdge(start: Node, ends: Node, condition: Bool) {
        // var checkStart: Node = start
        // var checkEnds: HashSet<String> = HashSet<String>()
        // for((choice, end) in ends) {
        //     checkNode(end, true)
        //     checkEnds.put(end)
        // }
        // if(this.checkEdge(checkStart, checkEnds)) {
        //     let startNode = this.nodes.get(start).getOrThrow()
        //     var endsName: HashMap<String, String> = HashMap<String, String>()
        //     for((choice, end) in ends) {
        //         endsName.put(choice, end)
        //     }
        //     startNode.addEdge(condition, endsName)
        // }
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
        let prompt = input["input"]
        let message = Message("user", prompt)
        state.messages.append(message)
        
        var nowInPut: String = prompt
        while(nowNode != endNode){
            println("nowNode: ${nowNode.nodeName}")
            nowNode.printEdges()
            if (nowNode == startNode) {
                nowNode = nowNode.edges.get(state.next).getOrThrow().end
                continue
            }
            let input = Dict()
            input["text"] = nowInPut
            let res: ResponseMessage = nowNode.runnable.getOrThrow().invoke(input)
            println(res.serialize().toJson())

            let obj: JsonObject = (res.serialize().toJson() as JsonObject).getOrThrow()
            
            if (((obj.get("tool_call").getOrThrow()) as JsonBool).getOrThrow().getValue()) {
                let toolCalls = (obj.get("tool_calls").getOrThrow() as JsonArray).getOrThrow()
                for (i in 0..toolCalls.size()) {
                    let toolCall = (toolCalls.get(i).getOrThrow() as JsonObject).getOrThrow()
                    let toolName = toolCall.get("name").getOrThrow().asString().getValue()
                    let toolInput = toolCall.get("arguments").getOrThrow().asObject()
                    println(toolName)
                    match(toolName) {
                        case "RouteDecider" => 
                            let next = RouteDecider().selectNext(toolInput)
                            println(next)
                            state.next = next
                        case _ =>
                            // println(toolName)
                            let tool = nodes.get(toolName).getOrThrow()
                            let toolRes = (tool.runnable.getOrThrow() as BaseTool).getOrThrow().invoke(toolInput)
                            let obs = (toolRes.serialize().toJson() as JsonObject).getOrThrow()
                            state.messages.append(Message("assistant", obs["content"].asString().getValue()))
                    }
                }
            } else {
                let content = obj.get("cont ent").getOrThrow().asString().getValue()
                state.next = nowNode.getOnlyEdge().end.nodeName
                state.messages.append(Message("assistant", content))
            }
        }
    }
}