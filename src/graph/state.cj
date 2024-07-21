package graph
import chain.*

public class State  {
    // the messages of the graph
    let messages: ArrayList<String> = ArrayList<String>()
    // The 'next' field indicates where to route to next
    let next: String = ""
}
