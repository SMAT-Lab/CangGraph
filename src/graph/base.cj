package graph
from std import collection.*
from std import reflect.*

public class Runnable<Input, Output> {
    public var input: Option<Input>
    public var output: Option<Output>
    public let name: String

    public init(input: Option<Input>, output: Option<Output>, name!: String) {
        this.input = input
        this.output = output
        this.name = name
    }

    public func getName(suffix!: Option<String> = Option<String>.None): String{
        return match(suffix) {
            case Some(string) => this.name + string
            case None => this.name
        }
    }

    public func getInputType(): TypeInfo{
        return TypeInfo.of(input)
    }

    public func getOutputType(): TypeInfo{
        return TypeInfo.of(output)
    }
}