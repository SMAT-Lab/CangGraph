package schema
from encoding import json.*

public abstract class OutputParser<OutputType> {
    public open func parse(output: Dict): OutputType 
}

// public class JsonOutputFunctionsParser {
//     public override func parse(output: String): JsonObject {
        
//     }
// }