package titoken

import onnx.*

from std import collection.*, convert.*, fs.*, os.posix.*, unicode.*
from encoding import json.*

public class Tokenizer {
    private let tokensJsonPath:String
    static let modelKey:String = "model"
    static let vocabKey:String = "vocab"
    static var tokens: HashMap<String, JsonValue> = HashMap<String, JsonValue>()
    static var tokensSize:Int32 = 0 
    // 后期改为单例
    //默认路径
    public init(tokensFilePath!:String = getcwd()+"/resource/tokenizer.json"){
         tokensJsonPath = tokensFilePath
        if(tokensSize == 0){
            let tokenallBytes: Array<Byte> = File.readFrom(tokensJsonPath)
            var tokenallStr = String.fromUtf8(tokenallBytes)
            var tokenJson: JsonValue = JsonValue.fromStr(tokenallStr).asObject().get(modelKey).getOrThrow().asObject().get(vocabKey).getOrThrow() 
            tokens  = tokenJson.asObject().getFields()
            tokensSize = Int32(tokens.size)
        }
    }

    public func getToken(s: String):Int64{
        var tokenStr:String = match(tokens.get(s)){
            case Some(x) => x.toString()
            case _ => "100"
        }
        var token : Int64 = Int64.parse(tokenStr)
        return token
    }
 
 
    public func  getTokensBySentence(sentence : String): ArrayList<Int64>{
        var encodedData = ArrayList<Int64>()
        encodedData.append(101)
        var sentenceTokens = sentence.toLower().split(" ")
        for(st in sentenceTokens){
            var size:Int64 = st.size
            var start:Int64 = 0
            var index = size
            var lasttoken = 100
            while(index > 0 ){
                //匹配上则若  start = i 
                //如果 start = st.let 则跳出 否则 i = let 重新循环  
                //如果 循环完都没有则 返回100    不是下标而是长度的话
                //解决 从后往前查询最开始没有值的问题
                var str = st[start..start+index]
                if(start != 0 && lasttoken != 100 ){
                    str="##"+str
                }
                var  token:Int64 = getToken(str)
                if(token != 100){
                    start = start + index
                    index = size - start
                    lasttoken = token
                    encodedData.append(lasttoken)
                } else if( index == 1 ){
                    // 这个情况是从后匹配完到最开始也没找到的话   
                    // 最末尾为100时未计算
                    start = start +1
                    index= size - start
                    lasttoken = 100
                    encodedData.append(lasttoken)
                } else{
                    index--
                }
                //最后都没匹配到的话 返回100 start 从 1开始
            }
        }
        encodedData.append(102)
        return encodedData
    }

    //中文分词为按字分,暂时不考虑英文
   public func  getTokensBySentenceChinese(sentence : String): ArrayList<ArrayList<Int64>>{
        var encodedDataArr= ArrayList<ArrayList<Int64>>()
        var encodedData = ArrayList<Int64>()
        //如果超过512则递减10并重新生成
        var encodedDataSize = 0
            encodedData.append(101)
        for(i in 0..sentence.size){
            var sentenceTokens: String = sentence[i].toString().toLower()
            var token:Int64 = getToken(sentenceTokens)
            encodedData.append(token)
            encodedDataSize++
            if(encodedDataSize == 511) {
                encodedData.append(102)
                encodedDataArr.append(encodedData.clone())
                //循环前10个token
                for(x in i..i-10 -1){
                    var sentenceTokens = sentence[i].toString().toLower()
                    var token:Int64 = getToken(sentenceTokens)
                    encodedData.append(token)
                }
                //将现有的
                encodedData.append(101)
                encodedDataSize = 0
                encodedData = ArrayList<Int64>()
            }
        }
        if(encodedDataSize>0){
        encodedData.append(102)
        encodedDataArr.append(encodedData)
        }
        return encodedDataArr
    }

    public operator func()(sentences: Array<String>): HashMap<String,IDArray>{
        //封装
        return  tokenizer(sentences)
    }

 

    public func tokenizer(sentences: Array<String>): HashMap<String, IDArray>{
        var encodedDatas:ArrayList <ArrayList <Int64>> = ArrayList <ArrayList<Int64>>()
        var maxSize = 0;
        for( sentence in sentences){
            var encodedData = getTokensBySentenceChinese(sentence)
            encodedDatas.appendAll(encodedData)
            if(encodedData[0].size>maxSize){
                maxSize = encodedData[0].size
            }
        }


        var tokenSize = encodedDatas.size
        var input_ids = Array<Array<Int64>>(tokenSize,item:Array<Int64>(maxSize,item:0))
        var token_type_ids = Array<Array<Int64>>(tokenSize,item:Array<Int64>(maxSize,item:0))
        var attention_mask = Array<Array<Int64>>(tokenSize,item:Array<Int64>(maxSize,item:0))

        for(  i in 0..tokenSize){
            var data =  encodedDatas[i].toArray()
            var size =  data.size

            data.copyTo(input_ids[i], 0,0,size)
            Array<Int64>(size,item:1).copyTo(attention_mask[i],0,0,size)
        }

        var token = HashMap<String,IDArray>()
        token["input_ids"] = XDArray<Int64>(input_ids)
        token["token_type_ids"] = XDArray<Int64>(token_type_ids)
        token["attention_mask"] = XDArray<Int64>(attention_mask)
        return token
    }

}
