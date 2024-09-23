package schema

from std import collection.*

public type Dict = HashMap<String, String>
public abstract class BaseMemory {
    public prop memoryVariables:Collection<Dict>
    public func loadMemoryVariable(input:Dict):Dict
    public func saveContext(outputs:Dict):Unit
    public func clear():Unit
}