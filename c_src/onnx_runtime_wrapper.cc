#include <vector>
#include <string>
#include <sstream>
#include <iostream>
#include <cstdint>
#include <cassert>

#include "include/onnxruntime_cxx_api.h"

typedef float float32_t;
typedef double float64_t;
typedef bool bool_t;

struct PInt64WithSize {
  int64_t *ptr;
  size_t size;
};

struct PPInt64WithSize {
  PInt64WithSize *ptr;
  size_t size;
};

struct PStrsWithSize {
  char **ptr;
  size_t size;
};

struct CXDArray {
  void *data;
  int64_t ndim;
  int64_t *shape;
};

// pretty prints a shape dimension vector
std::string print_shape(const std::vector<std::int64_t>& v) {
  std::stringstream ss("");
  for (std::size_t i = 0; i < v.size()-1; i++) {
    ss << v[i] << " ";
  }
  ss << v[v.size() - 1];
  return ss.str();
}

const char *TYPES_STR[] = {
  "TYPE_UNDEFINED",
  "TYPE_FLOAT",   // maps to c type float
  "TYPE_UINT8",   // maps to c type uint8_t
  "TYPE_INT8",    // maps to c type int8_t
  "TYPE_UINT16",  // maps to c type uint16_t
  "TYPE_INT16",   // maps to c type int16_t
  "TYPE_INT32",   // maps to c type int32_t
  "TYPE_INT64",   // maps to c type int64_t
  "TYPE_STRING",  // maps to c++ type std::string
  "TYPE_BOOL",
  "TYPE_FLOAT16",
  "TYPE_DOUBLE",      // maps to c type double
  "TYPE_UINT32",      // maps to c type uint32_t
  "TYPE_UINT64",      // maps to c type uint64_t
  "TYPE_COMPLEX64",   // complex with float32 real and imaginary components
  "TYPE_COMPLEX128",  // complex with float64 real and imaginary components
  "TYPE_BFLOAT16"     // Non-IEEE floating-point format based on IEEE754 single-precision
};

const int TYPES_SIZE[] = {
  -1,
  4,
  1,
  1,
  2,
  2,
  4,
  8,
  -1,
  1,
  2,
  8,
  4,
  8,
  8,
  16,
  2
};

void get_input_info(Ort::Session *session, PStrsWithSize &names, PStrsWithSize &types, PPInt64WithSize &shapes) {
  Ort::AllocatorWithDefaultOptions allocator;

  std::vector<std::string> input_names;
  std::vector<std::string> input_types;
  std::vector<std::vector<int64_t>> input_shapes;

  for (size_t i = 0; i < session->GetInputCount(); i++) {
    input_names.emplace_back(session->GetInputNameAllocated(i, allocator).get());
    input_types.push_back(TYPES_STR[(int)session->GetInputTypeInfo(i).GetTensorTypeAndShapeInfo().GetElementType()]);
    input_shapes.emplace_back(session->GetInputTypeInfo(i).GetTensorTypeAndShapeInfo().GetShape());
  }

  names.ptr = (char**)malloc(sizeof(char*)*input_names.size());
  names.size = input_names.size();
  types.ptr = (char**)malloc(sizeof(char*)*input_types.size());
  types.size = input_types.size();
  shapes.ptr = (PInt64WithSize*)malloc(sizeof(PInt64WithSize)*input_names.size());
  shapes.size = input_names.size();

  for (size_t i = 0; i < input_names.size(); i++) {
    names.ptr[i] = (char*)calloc(input_names[i].size() + 1, sizeof(char));
    strcpy(names.ptr[i], input_names[i].c_str());

    types.ptr[i] = (char*)calloc(input_types[i].size() + 1, sizeof(char));
    strcpy(types.ptr[i], input_types[i].c_str());

    shapes.ptr[i].ptr = (int64_t*)malloc(sizeof(int64_t)*input_shapes[i].size());
    memcpy(shapes.ptr[i].ptr, input_shapes[i].data(), sizeof(int64_t)*input_shapes[i].size());
    shapes.ptr[i].size = input_shapes[i].size();
  }
}

void get_output_info(Ort::Session *session, PStrsWithSize &names, PStrsWithSize &types, PPInt64WithSize &shapes) {
  Ort::AllocatorWithDefaultOptions allocator;

  std::vector<std::string> output_names;
  std::vector<std::string> output_types;
  std::vector<std::vector<int64_t>> output_shapes;

  for (size_t i = 0; i < session->GetOutputCount(); i++) {
    output_names.emplace_back(session->GetOutputNameAllocated(i, allocator).get());
    output_types.push_back(TYPES_STR[(int)session->GetOutputTypeInfo(i).GetTensorTypeAndShapeInfo().GetElementType()]);
    output_shapes.emplace_back(session->GetOutputTypeInfo(i).GetTensorTypeAndShapeInfo().GetShape());
  }

  names.ptr = (char**)malloc(sizeof(char*)*output_names.size());
  names.size = output_names.size();
  types.ptr = (char**)malloc(sizeof(char*)*output_types.size());
  types.size = output_types.size();
  shapes.ptr = (PInt64WithSize*)malloc(sizeof(PInt64WithSize)*output_names.size());
  shapes.size = output_names.size();

  for (size_t i = 0; i < output_names.size(); i++) {
    names.ptr[i] = (char*)calloc(output_names[i].size() + 1, sizeof(char));
    strcpy(names.ptr[i], output_names[i].c_str());

    types.ptr[i] = (char*)calloc(output_types[i].size() + 1, sizeof(char));
    strcpy(types.ptr[i], output_types[i].c_str());

    shapes.ptr[i].ptr = (int64_t*)malloc(sizeof(int64_t)*output_shapes[i].size());
    memcpy(shapes.ptr[i].ptr, output_shapes[i].data(), sizeof(int64_t)*output_shapes[i].size());
    shapes.ptr[i].size = output_shapes[i].size();
  }
}

Ort::Session* load_model(const char* path,const char* device) {
  Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "CangChain.onnx");
  Ort::SessionOptions session_options;
  if(strcmp( device, "cuda") == 0){
      OrtCUDAProviderOptions options;
      options.device_id = 0;
      options.arena_extend_strategy = 0;
      // options.cuda_mem_limit = (size_t)1 * 1024 * 1024 * 1024;//onnxruntime1.7.0
      options.gpu_mem_limit = (size_t)1 * 1024 * 1024 * 1024; //onnxruntime1.8.1, onnxruntime1.9.0
      options.cudnn_conv_algo_search = OrtCudnnConvAlgoSearch::OrtCudnnConvAlgoSearchExhaustive;
      options.do_copy_in_default_stream = 1;
      session_options.AppendExecutionProvider_CUDA(options);
    }
  Ort::Session *session = new Ort::Session(env, path, session_options);

  return session;
}

void run_inference(Ort::Session *session, PStrsWithSize& inp_names, PStrsWithSize &inp_types, CXDArray *arrays,
                   PStrsWithSize &out_names, CXDArray *out_arrays) {
  Ort::MemoryInfo mem_info =
      Ort::MemoryInfo::CreateCpu(OrtAllocatorType::OrtArenaAllocator, OrtMemType::OrtMemTypeDefault);
  std::vector<Ort::Value> input_tensors;

  for (size_t i = 0; i < inp_names.size; i++) {
    size_t eleSize = 1;
    for (int k = 0; k < arrays[i].ndim; k++) {
      eleSize *= arrays[i].shape[k];
    }

    if (strcmp(inp_types.ptr[i], "TYPE_DOUBLE") == 0) {
      input_tensors.emplace_back(
          Ort::Value::CreateTensor<float64_t>(mem_info, (float64_t*)arrays[i].data, eleSize,
                                              arrays[i].shape, arrays[i].ndim));
    } else if (strcmp(inp_types.ptr[i], "TYPE_FLOAT") == 0) {
      input_tensors.emplace_back(
          Ort::Value::CreateTensor<float32_t>(mem_info, (float32_t*)arrays[i].data, eleSize,
                                              arrays[i].shape, arrays[i].ndim));
    } else if (strcmp(inp_types.ptr[i], "TYPE_INT32") == 0) {
      input_tensors.emplace_back(
          Ort::Value::CreateTensor<int32_t>(mem_info, (int32_t*)arrays[i].data, eleSize,
                                              arrays[i].shape, arrays[i].ndim));
    } else if (strcmp(inp_types.ptr[i], "TYPE_INT64") == 0) {
      input_tensors.emplace_back(
          Ort::Value::CreateTensor<int64_t>(mem_info, (int64_t*)arrays[i].data, eleSize,
                                            arrays[i].shape, arrays[i].ndim));
    } else {
      std::cerr << "unsupport input type: " << inp_types.ptr[i] << std::endl;
      throw std::runtime_error("Model inference: unsupport input type");
    }
  }

  try {
    auto output_tensors = session->Run(Ort::RunOptions{nullptr}, inp_names.ptr, input_tensors.data(), inp_names.size,
                                       out_names.ptr, out_names.size);
    // double-check the dimensions of the output tensors
    // NOTE: the number of output tensors is equal to the number of otput nodes specified in the Run() call
    assert(output_tensors.size() == out_names.size && output_tensors[0].IsTensor());

    for (int i = 0; i < output_tensors.size(); i++) {
      auto &v = output_tensors[i];

      void *data = v.GetTensorMutableRawData();
      auto type_info = v.GetTypeInfo();
      auto tensor_info = type_info.GetTensorTypeAndShapeInfo();
      auto type_id = tensor_info.GetElementType();

      if (TYPES_SIZE[type_id] <= 0) {
        std::cerr << "unsupport output type: " << TYPES_SIZE[type_id] << std::endl;
        throw std::runtime_error("Model inference: unsupport output type");
      }

      std::vector<int64_t> shape = tensor_info.GetShape();
      size_t num_ele = 1;
      for (auto ii : shape) {
        num_ele *= ii;
      }
      // CAUTION! these memory need to be handled and released outside;
      void *o_data = malloc(num_ele*TYPES_SIZE[type_id]);
      void *o_shape = malloc(shape.size()*sizeof(int64_t));
      memcpy(o_data, data, num_ele*TYPES_SIZE[type_id]);
      memcpy(o_shape, shape.data(), shape.size()*sizeof(int64_t));
      out_arrays[i].data = o_data;
      out_arrays[i].ndim = shape.size();
      out_arrays[i].shape = (int64_t*)o_shape;
    }
  } catch (const Ort::Exception& exception) {
    std::cerr << "ERROR running model inference" << exception.what() << std::endl;
    throw std::runtime_error("Model inference: failed");
  }
}

extern "C" {
  void *c_load_model(const char* path,const char* device) {
    return (void*)load_model(path,device);
  }

  void c_get_model_info(void* modelPtr,
                        PStrsWithSize* inp_names, PStrsWithSize* inp_types, PPInt64WithSize* inp_shapes,
                        PStrsWithSize* out_names, PStrsWithSize* out_types, PPInt64WithSize* out_shapes) {
    Ort::Session *session = (Ort::Session*)modelPtr;
    get_input_info(session, *inp_names, *inp_types, *inp_shapes);
    get_output_info(session, *out_names, *out_types, *out_shapes);
  }

  void c_run_inference(void* modelPtr,
                       PStrsWithSize* inp_names, PStrsWithSize* inp_types, CXDArray *arrays,
                       PStrsWithSize* out_names, CXDArray *out_arrays) {
    Ort::Session *session = (Ort::Session*)modelPtr;
    run_inference(session, *inp_names, *inp_types, arrays, *out_names, out_arrays);
  }

  void c_free_model(void* modelPtr) {
    Ort::Session *session = (Ort::Session*)modelPtr;
    delete session;
  }

  void c_free_PStrsWithSize(PStrsWithSize *ptr) {
    for (size_t i = 0; i < ptr->size; i++) {
      free(ptr->ptr[i]);
    }
    free(ptr->ptr);
  }
  void c_free_PPInt64WithSize(PPInt64WithSize *ptr) {
    for (size_t i = 0; i < ptr->size; i++) {
      free(ptr->ptr[i].ptr);
    }
    free(ptr->ptr);
  }
}