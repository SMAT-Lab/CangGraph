#include <stdio.h>
#include "onnxruntime_c_api.h"

const  OrtApi* g_ort;
static OrtEnv* env ;
static OrtSession* session ;
static OrtSessionOptions* session_options ;


struct inputNodeData{
    const char*  name;
    float*  data;
    int64_t  data_len;
    int64_t* dims; 
    int64_t  dims_len;
};

struct outputData{
    float*  data;
    //张量  如 [3,7,384]
    int64_t* shape;
    int64_t shape_len;
};

void CheckStatus(OrtStatus* status)
{
    if (status != NULL) {
        const char* msg = g_ort->GetErrorMessage(status);
        fprintf(stderr, "%s\n", msg);
        g_ort->ReleaseStatus(status);
        exit(1);
    }
}

void  c_initializeSession(const char* path){
  //设置环境
    g_ort = OrtGetApiBase()->GetApi(ORT_API_VERSION);
    CheckStatus(g_ort->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "test", &env));
    CheckStatus (g_ort->CreateSessionOptions(&session_options));
    CheckStatus( g_ort->CreateSession(env, path, session_options, &session));
}

void c_nodeInfo(){
      OrtAllocator* allocator;
    CheckStatus(g_ort->GetAllocatorWithDefaultOptions(&allocator));
    size_t num_input_nodes;
    OrtStatus* status;
    status = g_ort->SessionGetInputCount(session, &num_input_nodes);
    const char* input_node_names[num_input_nodes];
    int64_t * input_node_dims = malloc(10 * sizeof(int));  
    printf("Number of inputs = %zu\n", num_input_nodes);

    for (size_t i = 0; i < num_input_nodes; i++) {
        char* input_name;
        status = g_ort->SessionGetInputName(session, i, allocator, &input_name);
        printf("Input %zu : name=%s\n", i, input_name);
        input_node_names[i] = input_name;

        // print input node types
        OrtTypeInfo* typeinfo;
        status = g_ort->SessionGetInputTypeInfo(session, i, &typeinfo);
        const OrtTensorTypeAndShapeInfo* tensor_info;
        CheckStatus(g_ort->CastTypeInfoToTensorInfo(typeinfo, &tensor_info));
        ONNXTensorElementDataType type;
        CheckStatus(g_ort->GetTensorElementType(tensor_info, &type));
        printf("Input %zu : type=%d\n", i, type);

        // print input shapes/dims
        size_t num_dims;
        CheckStatus(g_ort->GetDimensionsCount(tensor_info, &num_dims));
        printf("Input %zu : num_dims=%zu\n", i, num_dims);
        input_node_dims = malloc(num_dims * sizeof(int));  // simplify... this model has only 1 input node {1, 3, 224, 224}.
                                        
       CheckStatus( g_ort->GetDimensions(tensor_info, input_node_dims, num_dims));
        for (size_t j = 0; j < num_dims; j++)
            printf("Input %zu : dim %zu=%jd\n", i, j, input_node_dims[j]);

        g_ort->ReleaseTypeInfo(typeinfo);
    }
}

void printValueInfo(const OrtValue* value){
    const OrtTensorTypeAndShapeInfo* tensor_info;
        CheckStatus(g_ort->GetTensorTypeAndShape(value, &tensor_info));
        ONNXTensorElementDataType type;
        CheckStatus(g_ort->GetTensorElementType(tensor_info, &type));
        printf("type=%d\n", type);
        size_t num_dims;
        CheckStatus(g_ort->GetDimensionsCount(tensor_info, &num_dims));
        printf(" num_dims=%zu\n", num_dims);
        int64_t * input_node_dims = malloc(num_dims * sizeof(int));  // simplify... this model has only 1 input node {1, 3, 224, 224}.
                                        
       CheckStatus( g_ort->GetDimensions(tensor_info, input_node_dims, num_dims));
        for (size_t j = 0; j < num_dims; j++)
            printf(" dim %zu=%jd\n",  j, input_node_dims[j]);
}

void c_destroy(){
     
    g_ort->ReleaseSession(session);
    g_ort->ReleaseSessionOptions(session_options);
    g_ort->ReleaseEnv(env);
 }

void c_run(){
    //循环节点  设置数据，
    const char*  input_node_names [3]={"input_ids","token_type_ids","attention_mask"};
      
    const char* output_node_names[]={"last_hidden_state","924" };

    //  int64_t * input_node_dims[] = malloc(1 * sizeof(int));  //  input_node_dims
//    int64_t* input_node_dims[0]=2;
    int64_t  input_tensor_values[3][7] ={{101, 2169, 6251, 2003, 4991,  102,0},{101, 2023, 2003, 2019, 2742, 6251, 102}, { 101, 2169, 6251, 2003, 4991,  102, 0}};
    size_t  dsize = sizeof(input_tensor_values)*2;
    int64_t  input_node_dims[]={3,7};

    size_t  input_node_dims_len = sizeof(input_node_dims)/sizeof(input_node_dims[0]);
    // 节点数据
    OrtMemoryInfo* memory_info;
    CheckStatus(g_ort-> CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &memory_info));
    OrtValue* input_tensor = NULL;
    CheckStatus(  g_ort->CreateTensorWithDataAsOrtValue(memory_info, input_tensor_values, dsize, input_node_dims, input_node_dims_len, ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64, &input_tensor));


    int64_t  token_type_ids[3][7] ={{0, 0, 0, 0, 0,  0, 0},{0, 0, 0, 0, 0, 0, 0}, { 0, 0, 0, 0, 0, 0, 0} };
    size_t  token_type_ids_size = sizeof(token_type_ids)*2;
    // int64_t  input_node_dims[2]={5,7};
    //第二个节点数据
    OrtMemoryInfo* memory_info2;
    CheckStatus(g_ort-> CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &memory_info2));
    OrtValue* input_tensor1 = NULL;
    CheckStatus(  g_ort->CreateTensorWithDataAsOrtValue(memory_info2, token_type_ids, token_type_ids_size, input_node_dims, input_node_dims_len, ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64, &input_tensor1));
    

    int64_t  attention_mask[3][7]={{1, 1, 1, 1, 1, 1, 0},{1, 1, 1, 1, 1, 1, 1}, {1, 1, 1, 1, 1, 1, 0}};
    size_t  attention_masksize = sizeof(token_type_ids)*2;
    // int64_t  input_node_dims[2]={5,7};
    //第二个节点数据
    OrtMemoryInfo* memory_info3;
    CheckStatus(g_ort-> CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &memory_info3));
    OrtValue* input_tensor3 = NULL;
    CheckStatus(  g_ort->CreateTensorWithDataAsOrtValue(memory_info2, attention_mask, attention_masksize, input_node_dims, input_node_dims_len, ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64, &input_tensor3));
  
    OrtValue*  input_tensors[]={input_tensor,input_tensor1,input_tensor3};
// // run
    OrtValue* output_tensor = NULL;
    CheckStatus(  g_ort-> Run(session, NULL, input_node_names, (const OrtValue* const*)&input_tensors, 3, output_node_names,1, &output_tensor));
//  get data
    int64_t* shape;
    int64_t shape_len;
    getValueInfo(output_tensor,&shape,&shape_len);
    float* floatarr;
    CheckStatus( g_ort-> GetTensorMutableData(output_tensor, (void**)&floatarr)); 
    for (int i = 0; i <12; i++)
    printf("Score for class [%d] =  %f\n", i, floatarr[i]);
}


 void getValueInfo(const OrtValue* value,int64_t* size,int64_t* shape_len){
        const OrtTensorTypeAndShapeInfo* tensor_info;
        CheckStatus(g_ort->GetTensorTypeAndShape(value, &tensor_info));
        ONNXTensorElementDataType type;
        CheckStatus(g_ort->GetTensorElementType(tensor_info, &type));
        size_t num_dims;
        CheckStatus(g_ort->GetDimensionsCount(tensor_info, &num_dims));
        int64_t* input_node_dims = malloc(num_dims * sizeof(int));
        CheckStatus( g_ort->GetDimensions(tensor_info, input_node_dims, num_dims));
        *size = input_node_dims;
        *shape_len = num_dims;
}

struct outputData* c_runByInputNodeData(struct inputNodeData* arr, int size,const char* out_put_name) {
    const char*  input_node_names [size];
    OrtValue*  input_tensors[size];
    for (int i = 0; i < size; i++) {
        input_node_names[i] = arr[i].name;
        float*  data =  arr[i].data;
        
        int64_t* input_node_dims = arr[i].dims;
        size_t dims_len = arr[i].dims_len;
        size_t  dsize =arr[i].data_len;
        // printf( "%i\n" ,dsize);
        // 节点数据
        OrtMemoryInfo* memory_info;
        CheckStatus(g_ort-> CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &memory_info));
        OrtValue* input_tensor = NULL;
        CheckStatus(  g_ort->CreateTensorWithDataAsOrtValue(memory_info, data, dsize, input_node_dims, dims_len, ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64, &input_tensor));
        input_tensors[i]=input_tensor;
        g_ort->ReleaseMemoryInfo(memory_info);

    }
     OrtValue* output_tensor = NULL;
    CheckStatus(  g_ort-> Run(session, NULL, input_node_names, (const OrtValue* const*)&input_tensors, size, (const char* const*)&out_put_name, 1, &output_tensor));

    int64_t* shape;
    int64_t shape_len;
    getValueInfo(output_tensor,&shape,&shape_len);
    float* floatarr;
    CheckStatus( g_ort-> GetTensorMutableData(output_tensor, (void**)&floatarr));
    
    // struct outputData* out;
    // if (*floatarr != NULL) {
    //     free(*floatarr);
    //     *floatarr = NULL; // 避免野指针
    // }
    // if (floatarr != NULL) {
    //     free(floatarr);
    //     floatarr = NULL; // 避免野指针
    // }

    struct outputData *obj = (struct outputData*)malloc(sizeof(struct outputData));
    obj->data = floatarr;
    obj->shape = shape;
    obj->shape_len = shape_len;
    // for (int i = 0; i < shape_len ; i++){  
    //     printf("Score for class [%d] =  %f\n", i, floatarr[i]);
    // }
    // for (int i = 0; i < 384; i++){
    //     printf("Score for class [%d] =  %f\n", i, floatarr[i]);
    //     // printf("Score for class [%d] =  %f\n", i, obj->data[i]);
    //     }
    for(int i = 0; i < size; i++){
        g_ort->ReleaseValue(input_tensors[i]);
    }
    g_ort->ReleaseValue(output_tensor);
    return  obj;
}


void runMode(){
    const char* model_path = "/mnt/d/NLP/onnx/src/onnx/demo/model.onnx";
    c_initializeSession(model_path);
    //运行
    // c_nodeInfo();
    //  int64_t  input_tensor_values[3][7] ={{101, 2169, 6251, 2003, 4991,  102,0},{101, 2023, 2003, 2019, 2742, 6251, 102}, { 101, 2169, 6251, 2003, 4991,  102, 0}};
    int64_t  input_tensor_values[] ={ 101, 13138, 12521, 21486, 21926,   102 , 101,   102,     0,     0,     0,     0};
     
    size_t  dsize = sizeof(input_tensor_values)*2;
    // int64_t  token_type_ids[3][7] ={{0, 0, 0, 0, 0,  0, 0},{0, 0, 0, 0, 0, 0, 0}, { 0, 0, 0, 0, 0, 0, 0} };
    int64_t  token_type_ids[12] ={0, 0, 0, 0, 0,  0, 0,0, 0, 0, 0};
    size_t  token_type_ids_size = sizeof(token_type_ids)*2;
    int64_t  attention_mask[12]={1,1,1,1,1,1,1,1,0,0,0,0};
    size_t  attention_masksize = sizeof(token_type_ids)*2;
    int64_t* dims[]={2,6};
    size_t dims_len = sizeof(dims) / sizeof(dims[0]);


    const char* output_node_names="last_hidden_state";
     struct inputNodeData inputNodeDatas[] = {
        {"input_ids", input_tensor_values,dsize,dims,dims_len}
        ,{"token_type_ids",token_type_ids,token_type_ids_size,dims,dims_len}
        ,{"attention_mask",attention_mask,attention_masksize,dims,dims_len}
    };
    
    int size = sizeof(inputNodeDatas) / sizeof(inputNodeDatas[0]);
    struct outputData* od=c_runByInputNodeData(inputNodeDatas,size,output_node_names);
    // c_run( );
    c_destroy();
   
}
int main(int argc, char* argv[]) {
    
    for (int i = 0; i < 3 ; i++){
        runMode();
        printf("运行模型\n");
    }
    return 0;
    
}