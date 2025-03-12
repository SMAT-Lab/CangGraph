package canggraph.schema

import encoding.json.*

public abstract class OutputParser<OutputType> {
    public open func parse(output: Dict): OutputType 
}

public class MockOutputParser <: OutputParser<MockOutputParser> {
    public override func parse(output: Dict): MockOutputParser {
        let result = MockOutputParser()
        return result
    }
}

// public class JsonOutputFunctionsParser {
//     public override func parse(output: String): JsonObject {
        
//     }
// }