package canggraph.onnx

public interface XCtype {
    static func size(): Int64
    static func typeId(): Int64
    static func name() : String
}

extend Float32 <: XCtype {
    public static func size(): Int64 {
        return 4
    }
    public static func typeId(): Int64 {
        return 0
    }
    public static func name(): String {
        return "float32"
    }
}

extend Float64 <: XCtype {
    public static func size(): Int64 {
        return 8
    }
    public static func typeId(): Int64 {
        return 1
    }
    public static func name(): String {
        return "float64"
    }
}

extend Int32 <: XCtype {
    public static func size(): Int64 {
        return 4
    }
    public static func typeId(): Int64 {
        return 2
    }
    public static func name(): String {
        return "int32"
    }
}

extend Int64 <: XCtype {
    public static func size(): Int64 {
        return 8
    }
    public static func typeId(): Int64 {
        return 3
    }
    public static func name(): String {
        return "int64"
    }
}

extend Float16 <: XCtype {
    public static func size(): Int64 {
        return 2
    }
    public static func typeId(): Int64 {
        return 4
    }
    public static func name(): String {
        return "float16"
    }
}

extend Int16 <: XCtype {
    public static func size(): Int64 {
        return 2
    }
    public static func typeId(): Int64 {
        return 5
    }
    public static func name(): String {
        return "int16"
    }
}

extend Bool <: XCtype {
    public static func size(): Int64 {
        return 1
    }
    public static func typeId(): Int64 {
        return 6
    }
    public static func name(): String {
        return "bool_"
    }
}

extend Array<T> where T <: CType & XCtype {
    func toCPointer() : CPointer<T> {
        unsafe {
            let valuePtr = acquireArrayRawData(this)
            let len = UIntNative(this.size*T.size())
            var dataPtr = malloc(len)
            memcpy(dataPtr, CPointer<Unit>(valuePtr.pointer), len)
            releaseArrayRawData(valuePtr)
            return CPointer<T>(dataPtr)
         }
    }
}