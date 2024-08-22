package graph

public class RouteDecider {
    public var name: String = "RouteDecider"
    public func selectNext(input: JsonObject): String {
        let next = input["Next"].asString().getValue()
        return next[1..next.size-1]
    }
}