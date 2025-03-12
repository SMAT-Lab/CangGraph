package canggraph.titoken

import canggraph.onnx.*

import std.{collection.*, math.*}

public class Embedder{
    private let model:ONNXModel
    private let tokenizer: Tokenizer
    public let embedding_dim: Int32

    public init(model :ONNXModel, tokenizer : Tokenizer, embedding_dim!:Int32 = 768){
        this.model = model
        this.tokenizer = tokenizer
        this.embedding_dim = embedding_dim
    }

    public init(modelPath!:String = getcwd()+"/resource/embedding_model.onnx",
                tokensFilePath!:String = getcwd()+"/resource/tokenizer.json",
                embedding_dim!:Int32 = 768){
        this.model = ONNXModel(path: modelPath)
        this.tokenizer = Tokenizer(tokensFilePath:tokensFilePath)
        this.embedding_dim = embedding_dim
    }

    public operator func()(sentences: Array<String>):ArrayList<ArrayList<Float32>>{
        var encodeInput = this.tokenizer(sentences)
        var res = this.model(encodeInput)
        // for ((k, v) in res) {
        //     println(k)
        //     println(v)
        // }
        let last_hidden_state = (res["last_hidden_state"] as XDArray<Float32>).getOrThrow()
        //根据向量维度拆分
        //池化
        let attention_mask = (encodeInput["attention_mask"] as XDArray<Int64>).getOrThrow()
        var sentence_embeddings = mean_pooling(last_hidden_state, attention_mask)
        //归一化
        sentence_embeddings = normalize(sentence_embeddings)

        return sentence_embeddings
    }
    
    /*
    *转化为三维数组
    */
    public func getData(last_hidden_state:XDArray<Float32>):ArrayList<ArrayList<ArrayList<Float32>>>{
        var shape = last_hidden_state.shape
        var data = ArrayList<ArrayList<ArrayList<Float32>>>()
        var shapeData =[0,0,0]
        for(i in 0..shape[0]){
            shapeData[0] = i
            data.append(getData(shapeData,last_hidden_state))
        }
        return data
    }
    /*
    *转化为二维数组
    */
    public func getData( shapeData:Array<Int64> , last_hidden_state:XDArray<Float32>):ArrayList<ArrayList<Float32>>{
        var shape = last_hidden_state.shape
        var data = ArrayList<ArrayList<Float32>>()
        for(i in 0..shape[1]){
            shapeData[1] = i
            data.append(getEndShapeData(shapeData,last_hidden_state))
        }
        return data
    }
    // /*
    // *转化为一维数组
    // */
    public func getEndShapeData(shapeData:Array<Int64>, last_hidden_state:XDArray<Float32>):ArrayList<Float32>{
        var shape = last_hidden_state.shape
        var data = ArrayList<Float32>()
        for(i in 0..shape[2]){
            shapeData[2] = i 
            data.append(last_hidden_state[shapeData])
        }
        return data
    }
    /*
    *池化  
    *将embeding数据与attention_mask向乘的总和 除以attention_mask 转换为二维数组
    */
     public func mean_pooling(model_output:XDArray<Float32>,attention_mask:XDArray<Int64> ):ArrayList<ArrayList<Float32>>{
        var shape = model_output.shape
        var average_data:ArrayList<ArrayList<Float32>> =  ArrayList<ArrayList<Float32>>()
        for( l1 in  0..shape[0]){
            var l1_average_data:ArrayList<Float32> = ArrayList<Float32>()
            for( l3 in  0..shape[2]){
                var l3_sum_data:Float32 = 0.0f32
                var l3_mask_data:Float32 = 0.0f32
                for(l2 in 0..shape[1]){
                    var l2_mask_data:Float32 = Float32(attention_mask[l1,l2])
                    var l2_sum_data:Float32 = model_output[l1,l2,l3]*l2_mask_data
                    l3_sum_data = l3_sum_data + l2_sum_data
                    l3_mask_data = l3_mask_data + l2_mask_data
                }
                l1_average_data.append(l3_sum_data/l3_mask_data)
            }
            average_data.append(l1_average_data)
        }
        return average_data
    }
/*
*归一化  
*将数组平方的总和除以平均
*/

    public func  normalize(average_data:ArrayList<ArrayList<Float32>>):ArrayList<ArrayList<Float32>>{
        var sentence_embeddings:ArrayList<ArrayList<Float32>>  =  ArrayList<ArrayList<Float32>>() 
        //循环求平方和
        for(data in average_data ){
                var sentence_embedding:ArrayList<Float32> = ArrayList<Float32>()
                var example:Float32 = 1e-12
                var sum:Float32 = 0.0
                for(d in data){
                    sum = sum + d*d
                }
                example = math.sqrt(sum)
                for(d in data){
                    sentence_embedding.append(d/example)
                }
                sentence_embeddings.append(sentence_embedding)
        }  
            return sentence_embeddings;
    }

}



