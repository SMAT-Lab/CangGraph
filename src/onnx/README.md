Onnx库：用于运行本地小模型的库，参考：https://github.com/microsoft/onnxruntime

注: 当前仅支持模型的加载和推理。一些前处理(比如tokenizer, padding等)和后处理过程需要使用者自己考虑。

## ONNXModel
提供 `ONNXModel` 类，用以加载onnx模型。暂时只支持CPU上的模型推理。
返回的数据结构是自定义的高维数组 `XDArray`，可以通过 `toArray` 方法转成一维仓颉Array使用。

使用方式参考如下代码
```swift
// 加载模型
let model = ONNXModel("model.onnx")
// 输出模型信息，需要根据模型的输入信息，定制模型的输入
println("${model}\n");

var encodeInput = HashMap<String, IDArray>()

encodeInput["input_ids"] = XDArray<Int64>([[101, 2023, 2003, 2019, 2742, 6251, 102],
                                           [101, 2169, 6251, 2003, 4991,  102,   0]])
encodeInput["token_type_ids"] = XDArray<Int64>([[0, 0, 0, 0, 0, 0, 0],
                                                [0, 0, 0, 0, 0, 0, 0]])
encodeInput["attention_mask"] = XDArray<Int64>([[1, 1, 1, 1, 1, 1, 1],
                                                [1, 1, 1, 1, 1, 1, 0]])
var res = model(encodeInput)
for ((k, v) in res) {
    println(k)
    println(v)
}
```


## 用例测试
### 下载模型
从 https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/tree/main 下载模型

### 转成onnx模型
原始下载的模型格式包含pytorch、tensorflow等格式，但不包含onnx格式。需要将模型转成onnx格式，利用huggingface提供的转换库可以办到。转换脚本如下
```python
import sys
from optimum.onnxruntime import ORTModel, ORTModelForFeatureExtraction
from transformers import AutoTokenizer

model_checkpoint = "./all-MiniLM-L6-v2/"
save_directory = "./all-MiniLM-L6-v2_onnx/"

# Load a model from transformers and export it to ONNX
ort_model = ORTModelForFeatureExtraction.from_pretrained(model_checkpoint, export=True)

# export to onnx format
ort_model.save_pretrained(save_directory)
```

### 执行测试
onnx文件加下的 onnx_model_test.cj 文件包含了测试代码，按照cjc标准的跑测试用例的方法即可。

也可以参考 build.sh 中的代码，执行 `bash build.sh test`

### 结果验证
按照当前的输入，测试用例的输入结果如下
```
Model Path: model.onnx
inputs:
	input_ids: [-1 -1]    TYPE_INT64
	attention_mask: [-1 -1]    TYPE_INT64
	token_type_ids: [-1 -1]    TYPE_INT64
inputs:
	last_hidden_state: [-1 -1 384]    TYPE_FLOAT


last_hidden_state
[[[ 0.036565 -0.016161  0.168245 ...  0.055408 -0.164439 -0.296698]
  [ 0.723910  0.639947  0.188784 ...  0.594550  0.620567  0.489683]
  [ 0.006378  0.020305  0.044757 ...  0.346382  1.316988 -0.166955]
  ...
  [ 0.147919 -0.064261  0.145694 ...  0.883739 -0.331558  0.297532]
  [ 0.521247  0.656297  0.560700 ... -0.039890  0.041214 -1.403565]
  1 .git/
  [ 1.082411  0.714034  0.398592 ... -0.230053  0.324314 -1.031278]]

 [[ 0.280219  0.116473 -0.041788 ...  0.271054 -0.168468 -0.296114]
  [ 0.872946  0.454480 -0.109097 ...  0.136549  0.457972 -0.204151]
  [ 0.475162  0.573107  0.630442 ...  0.652569  0.561242 -1.326843]
  ...
  [ 0.611331  0.792035 -0.468485 ...  0.085432  1.059156 -0.298329]
  [ 0.411506  1.094570  0.238544 ...  0.898364  0.368357 -0.733289]
  [ 0.137449  0.555544  0.267774 ...  0.542625  0.466516 -0.528355]]]
```

和原始的pyton程序验证对比过，输出结果是一致的。

隐私模型：  https://pan.baidu.com/s/1Rs4ya67XV1K_qTv9XE1-Qg?pwd=fc5t 提取码: fc5t  