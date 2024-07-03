package graph
from std import collection.*, log.*
import schema.*

public class Graph {
    public var nodes: Dict = Dict()
    public var edges: HashMap<String, HashMap<String, Bool>> = HashMap()
    public var support_multiple_edges: Bool = false
    public var compiled: Bool = false
    let logger: SimpleLogger = SimpleLogger()

    public func get_all_edges(): HashMap<String, HashMap<String, Bool>> {
        return edges
    }

    public func add_node(node: String, action: Option<String> ) {
        if ( compiled == false ) {
            logger.log(LogLevel.WARN, "Adding node to graph before compilation")
        }
        if ( nodes.get(node) != None ) {
            logger.log(LogLevel.WARN, "Node ${node} already exists in graph")
        }

        if ( node == END || node == START ) {
            logger.log(LogLevel.WARN, "Node ${node} is a reserved node name")
        }

        // 把action转换为runnable的东西

        nodes.put(node, action.getOrThrow())
    }

    public func add_edge(start: String, end: String) {
        if ( compiled == false ) {
            logger.log(LogLevel.WARN, "Adding edge to graph before compilation")
        }

        if ( start == END) {
            logger.log(LogLevel.WARN, "END cannot be a start node")
        }

        if ( end == START ) {
            logger.log(LogLevel.WARN, "START cannot be an end node")
        }

        if ( support_multiple_edges == false && edges.get(start).getOrThrow().get(end) != None) {
            logger.log(LogLevel.WARN, "Edge (${start}, ${end}) already exists in graph")
        }

        let start_edges = edges.get(start).getOrThrow()
        start_edges.put(end, true)

        edges.put(start, start_edges)
    }

    public func add_conditional_edges(source: String, path_map: Dict, then: Option<String>) {
        // TODO
    }

    public func set_entry_point(key: String) {
        add_edge(START, key)
    }

    public func set_finish_point(key: String) {
        add_edge(key, END)
    }

    public func compile() {
        
    }

}

