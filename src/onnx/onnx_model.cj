package onnx
from std import collection.*
from std  import  os.posix.*

foreign func c_load_model(path: CString,option: CString): CPointer<Unit>
foreign func c_free_model(modelPtr: CPointer<Unit>) : Unit
foreign func c_free_PStrsWithSize(ptr: CPointer<PStrsWithSize>): Unit
foreign func c_free_PPInt64WithSize(ptr: CPointer<PPInt64WithSize>): Unit
foreign func c_get_model_info(modelPtr: CPointer<Unit>,
                              inp_names: CPointer<PStrsWithSize>, inp_types: CPointer<PStrsWithSize>,
                              inp_shapes: CPointer<PPInt64WithSize>,
                              out_names: CPointer<PStrsWithSize>, out_types: CPointer<PStrsWithSize>,
                              out_shapes: CPointer<PPInt64WithSize>): Unit
foreign func c_run_inference(modelPtr: CPointer<Unit>,
                             inp_names: CPointer<PStrsWithSize>, inp_types: CPointer<PStrsWithSize>,
                             arrays: CPointer<CXDArray>,
                             out_names: CPointer<PStrsWithSize>, out_arrays: CPointer<CXDArray>): Unit

@C
struct PInt64WithSize {
    var ptr: CPointer<Int64>
    var size: UIntNative
    public init() {
        ptr = CPointer<Int64>()
        size = 0;
    }
}

@C
struct PPInt64WithSize {
    var ptr: CPointer<PInt64WithSize>
    var size: UIntNative
    public init() {
        ptr = CPointer<PInt64WithSize>()
        size = 0;
    }
}

@C
struct PStrsWithSize {
    var ptr: CPointer<CString>
    var size: UIntNative
    public init() {
        ptr = CPointer<CString>()
        size = 0
    }
}

public enum OnnxDeviceOption {
    | CPU
    | CUDA
}

func OnnxDevice(option: OnnxDeviceOption ): String {
    match(option) {
        case CPU => "cpu"
        case CUDA => "cuda"
    }
}

public class ONNXModel <: ToString {
    var model_path: String 
    var session: CPointer<Unit>
    var input_names: CPointer<PStrsWithSize>
    var input_types: CPointer<PStrsWithSize>
    var input_shapes: CPointer<PPInt64WithSize>
    var output_names: CPointer<PStrsWithSize>
    var output_types: CPointer<PStrsWithSize>
    var output_shapes: CPointer<PPInt64WithSize>

    public init(path!: String = getcwd()+"/resource/privacy/privacy_model.onnx",option!:OnnxDeviceOption = CPU) {
        model_path = path 
        var p = unsafe { LibC.mallocCString(path) }
        println("tensor.device: ${OnnxDevice(option)}")
        var o = unsafe { LibC.mallocCString(OnnxDevice(option)) }  
        session = unsafe { c_load_model(p,o) }
        unsafe { LibC.free(p) }
        
        input_names = unsafe { LibC.malloc<PStrsWithSize>() }
        input_types = unsafe { LibC.malloc<PStrsWithSize>() }
        input_shapes = unsafe { LibC.malloc<PPInt64WithSize>() }
        output_names = unsafe { LibC.malloc<PStrsWithSize>() }
        output_types = unsafe { LibC.malloc<PStrsWithSize>() }
        output_shapes = unsafe { LibC.malloc<PPInt64WithSize>() }
        unsafe { c_get_model_info(session,
                                  input_names, input_types, input_shapes,
                                  output_names, output_types, output_shapes) }
    }


    ~init() {
        unsafe { c_free_model(session) }
        unsafe { c_free_PStrsWithSize(input_names) }
        unsafe { c_free_PStrsWithSize(output_names) }
        unsafe { c_free_PStrsWithSize(input_types) }
        unsafe { c_free_PStrsWithSize(output_types) }
        unsafe { c_free_PPInt64WithSize(input_shapes) }
        unsafe { c_free_PPInt64WithSize(output_shapes) }

        unsafe { LibC.free(input_names) }
        unsafe { LibC.free(output_names) }
        unsafe { LibC.free(input_types) }
        unsafe { LibC.free(output_types) }
        unsafe { LibC.free(input_shapes) }
        unsafe { LibC.free(output_shapes) }
    }

    public operator func ()(token:HashMap<String,Array<Array<Int64>>>): HashMap<String, IDArray> {
            var encodeInput = HashMap<String, IDArray>()
            for((k,v) in token){
                encodeInput[k] = XDArray<Int64>(v)
            }
            return (encodeInput);
    }

    public operator func ()(inputs: HashMap<String, IDArray>) : HashMap<String, IDArray> {
        var ret = HashMap<String, IDArray>()
        var inp_names = unsafe { input_names.read() }
        var out_names = unsafe { output_names.read() }
        var arrays: CPointer<CXDArray> = unsafe { LibC.malloc<CXDArray>(count: Int64(inp_names.size)) }
        var out_arrays: CPointer<CXDArray> = unsafe { LibC.malloc<CXDArray>(count: Int64(out_names.size)) }

        try {
            for (i in 0..inp_names.size) {
                var name = unsafe { inp_names.ptr.read(Int64(i)).toString() }
                if (!inputs.contains(name)) {
                    throw Exception("invalid input, lack input of name [$name]")
                }
                var arr = inputs[name]
                var array = CXDArray()
                array.data = arr.getData()
                array.nDim = arr.getShapeDims()
                array.shape = arr.getShapePtr()
                unsafe { arrays.write(Int64(i), array) }
            }

            unsafe {
                c_run_inference(session, input_names, input_types, arrays, output_names, out_arrays)
            }
            var out_types = unsafe { output_types.read() }
            for (i in 0..out_names.size) {
                var name = unsafe { out_names.ptr.read(Int64(i)).toString() }
                let array = unsafe { out_arrays.read(Int64(i)) }
                var shape = Array<Int64>(array.nDim, item: 0)
                for (ii in 0..array.nDim) {
                    shape[ii] = unsafe { array.shape.read(ii) }
                }
                unsafe { free(CPointer<Unit>(array.shape)) }
                var type_str = unsafe { out_types.ptr.read(Int64(i)).toString() }
                if (type_str == "TYPE_FLOAT") {
                    ret[name] = XDArray<Float32>(CPointer<Float32>(array.data), shape)
                } else if (type_str == "TYPE_INT64") {
                    ret[name] = XDArray<Int64>(CPointer<Int64>(array.data), shape)
                } else if (type_str == "TYPE_INT32") {
                    ret[name] = XDArray<Int32>(CPointer<Int32>(array.data), shape)
                } else if (type_str == "TYPE_DOUBLE") {
                    ret[name] = XDArray<Float64>(CPointer<Float64>(array.data), shape)
                } else {
                    throw Exception("unsupport output type, [${name}: ${type_str}]")
                }
            }
        }
        catch (e: Exception) {
            println("Error: ${e.toString()}")
        }

        return ret
    }

     public override func toString(): String {
         var ss = "Model Path: ${model_path}\n"
         ss += "inputs:\n"
        var input_names = unsafe { input_names.read() }
        var input_types = unsafe { input_types.read() }
        var input_shapes = unsafe { input_shapes.read() }
        for (i in 0..input_names.size) {
            ss += unsafe { "\t${input_names.ptr.read(Int64(i)).toString()}: [" }
            var shape: PInt64WithSize = unsafe { input_shapes.ptr.read(Int64(i)) }
            for (j in 0..shape.size) {
                ss += unsafe { "${shape.ptr.read(Int64(j))}" }
                if (j < shape.size - 1) {
                    ss += " "
                }
            }
            ss += "]"
            ss += unsafe { "    ${input_types.ptr.read(Int64(i)).toString()}" }
            ss += "\n"
        }

        ss += "inputs:\n"
        var output_names = unsafe { output_names.read() }
        var output_types = unsafe { output_types.read() }
        var output_shapes = unsafe { output_shapes.read() }
        for (i in 0..output_names.size) {
            ss += unsafe { "\t${output_names.ptr.read(Int64(i)).toString()}: [" }
            var shape: PInt64WithSize = unsafe { output_shapes.ptr.read(Int64(i)) }
            for (j in 0..shape.size) {
                ss += unsafe { "${shape.ptr.read(Int64(j))}" }
                if (j < shape.size - 1) {
                    ss += " "
                }
            }
            ss += "]"
            ss += unsafe { "    ${output_types.ptr.read(Int64(i)).toString()}" }
            ss += "\n"
        }
        return ss
    }
}