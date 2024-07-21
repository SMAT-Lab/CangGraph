package graph
from std import collection.*, log.*
from encoding import json.*
import schema.*
import agent.*
import tool.*

public class Edge {
    let start: String
    let ends: HashMap<String, String>
    let condition: Option<String>
    public init(start: String, end: String) {
        this.condition = None<String>
        this.start = start
        var ends = HashMap<String, String>()
        ends.put("", end)
        this.ends = ends
    }

    public init(start: String, condition: String, ends: HashMap<String, String>) {
        this.start = start
        this.condition = condition
        this.ends = ends
    }
}

public class Node {
    let nodeName: String
    let nodeType: String
    var edges: HashMap<Option<String>, Edge> = HashMap<Option<String>, Edge>()
    var message: String = String()
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

    func addEdge(end: String) {
        let edge: Edge = Edge(nodeName, end)
        edges.put(None<String>, edge)
    }

    func addEdge(condition: String, ends: HashMap<String, String>) {
        let edge: Edge = Edge(nodeName, condition, ends)
        edges.put(condition, edge)
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
    let state: State = State()
    let logger: SimpleLogger = SimpleLogger()
    let startNode = Node(START, START)
    let endNode = Node(END, END)
    public init() {
        nodes.put(START, startNode)
        nodes.put(END, endNode)
    }

    private func checkNode(nodeName: String, existence: Bool): Bool {
        // if (compiled == false) {
        //     logger.log(LogLevel.ERROR, "Adding node to graph before compilation")
        //     return false
        // }
        if (existence != nodes.contains(nodeName)) {
            if(existence) {
                logger.log(LogLevel.ERROR, "Node ${nodeName} doesn't exist in graph")
            }
            else {
                logger.log(LogLevel.ERROR, "Node ${nodeName} already exists in graph")
            }
            
            return false
        }
        return true
    }

    public func addNode(nodeName: String, nodeType: String) {
        if (nodeName == END || nodeName == START) {
            logger.log(LogLevel.ERROR, "Node ${nodeName} is a reserved node name")
            return
        }
        if (checkNode(nodeName, false)) {
            var node = Node(nodeName, nodeType)
            this.nodes.put(nodeName, node)
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

    public func addEdge(start: String, end: String) {
        var checkStart: String = start
        var checkEnds: HashSet<String> = HashSet<String>()
        checkNode(end, true)
        checkEnds.put(end)
        if(this.checkEdge(checkStart, checkEnds)) {
            let startNode = this.nodes.get(start).getOrThrow()
            startNode.addEdge(end)
        }
    }

    public func addEdge(start: String, condition: String, ends: HashMap<String, String>) {
        var checkStart: String = start
        var checkEnds: HashSet<String> = HashSet<String>()
        for((choice, end) in ends) {
            checkNode(end, true)
            checkEnds.put(end)
        }
        if(this.checkEdge(checkStart, checkEnds)) {
            let startNode = this.nodes.get(start).getOrThrow()
            var endsName: HashMap<String, String> = HashMap<String, String>()
            for((choice, end) in ends) {
                endsName.put(choice, end)
            }
            startNode.addEdge(condition, endsName)
        }
    }

    public func setEntryPoint(nodeName: String) {
        if(checkNode(nodeName, true)) {
            startNode.addEdge(nodeName)
        }
    }

    public func avoke(prompt: String) {
        var nowNode: String = START
        var nowInPut: String = prompt
        while(nowNode != END){
            if(nowNode == START) {
                nowNode = this.startNode.edges[None<String>].ends[""]
            }
            else {
                let input = Dict()
                input["input"] = nowInPut
                let res = this.nodes.get(nowNode).getOrThrow().runnable.getOrThrow().avoke(input)
            }
        } 
    }

}