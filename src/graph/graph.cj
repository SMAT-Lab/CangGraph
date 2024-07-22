package graph
from std import collection.*, log.*
from encoding import json.*
import schema.*
import agent.*
import tool.*
import chain.*

public class State  {
    // the messages of the graph
    var messages: ArrayList<String> = ArrayList<String>()
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

    public operator func !=(other: Node): Bool {
        return this.nodeName != other.nodeName
    }

    public operator func ==(other: Node): Bool {
        return this.nodeName == other.nodeName
    }

    public func run(input: Dict): JsonObject {
        match (runnable) {
            case None => return JsonObject()
            case Some(node) => 
                if (node is CoTChain) {
                    return (node as CoTChain).getOrThrow().avoke(input)
                } else if (node is BaseTool) {
                    return (node as BaseTool).getOrThrow().avoke(input)
                } else if (node is create_openai_tools_agent) {
                    return (node as create_openai_tools_agent).getOrThrow().avoke(input)
                } 
                else {
                    return JsonObject()
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

    public func avoke(input: Dict) {
        var nowNode: Node = startNode
        let prompt = input["input"]
        var nowInPut: String = prompt
        while(nowNode != endNode){
            nowNode = nowNode.edges.get(state.next).getOrThrow().end
            let input = Dict()
            input["input"] = nowInPut
            let res = nowNode.runnable.getOrThrow().avoke(input)
            println("${nowNode.nodeName}: ${(res["content"] as JsonValue).getOrThrow()}")
        } 
    }

}