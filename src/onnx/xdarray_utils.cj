package onnx
from std import math.*

foreign {
    func malloc(size: UIntNative): CPointer<Unit>
    func calloc(nelem: UIntNative, size: UIntNative): CPointer<Unit>
    func free(p: CPointer<Unit>): Unit
    func memcpy(dest: CPointer<Unit>, src: CPointer<Unit>, size: UIntNative): CPointer<Unit>
}

enum NDLogLevel {
    | DEBUG
    | INFO
    | WARNING
    | ERROR
}

func NDLOG(level: NDLogLevel, msg: String): Unit {
    match(level) {
        case DEBUG => println("DEBUG: ${msg}")
        case INFO => println("INFO: ${msg}")
        case WARNING => println("WARNING: ${msg}")
        case ERROR => println("ERROR: ${msg}")
                      throw Exception()
    }
}

func IsPositive(arr: Array<Int64>): Bool
{
    for (i in arr) {
        if (i <= 0) {
            return false
        }
    }
    return true
}

public func ShapeMul(arr: Array<Int64>, scalarMode!: Bool = false): Int64
{
    if (arr.size == 0) {
        if (scalarMode) {
            return 1
        } else {
            return 0
        }
    }
    var res = 1
    for (i in arr) {
        res = res*i
    }
    return res
}

public func CheckIndex(index: Array<Int64>, dims: Array<Int64>):Bool {
    for (i in 0..index.size) {
        if (!(0 <= index[i] && index[i] < dims[i])) {
            return false
        }
    }
    return true
}