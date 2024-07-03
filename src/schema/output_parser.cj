package schema

public abstract class OutputParser<OutputType> {
    public open func parse(output: Dict): OutputType 
}
