from transformers import BertTokenizer, BertModel
import torch

# Mean Pooling - Take attention mask into account for correct averaging
def mean_pooling(model_output, attention_mask):
    token_embeddings = model_output[0]  # First element of model_output contains all token embeddings
    input_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
    return torch.sum(token_embeddings * input_mask_expanded, 1) / torch.clamp(input_mask_expanded.sum(1), min=1e-9)

# Load model from HuggingFace Hub
tokenizer = BertTokenizer.from_pretrained('shibing624/text2vec-base-chinese')
model = BertModel.from_pretrained('shibing624/text2vec-base-chinese')

sentences = ["苍穹是什么","苍穹用来形容广阔的天空、壮阔的景象，代表着壮阔、辽阔的意境。比如《诗经》中的“苍苍者天”，《庄子》中的“苍苍乎如在其上”的描述。苍穹常常被用来比喻高远的理想或抱负，也可以指代神话中的天空之神"]
# Tokenize sentences
encoded_input = tokenizer(sentences, padding=True, truncation=True, return_tensors='pt')
print(encoded_input)
# Compute token embeddings
with torch.no_grad():
    model_output = model(**encoded_input)
   
# Perform pooling. In this case, mean pooling.
sentence_embeddings = mean_pooling(model_output, encoded_input['attention_mask'])
# print(sentence_embeddings.size())
print("Sentence embeddings:")
print(sentence_embeddings)

torch.onnx.export(model,         # model being run 
        encoded_input,       # model input (or a tuple for multiple inputs) 
        "./Network.onnx",       # where to save the model  
        export_params=True,  # store the trained parameter weights inside the model file 
        opset_version=11,    # the ONNX version to export the model to 
        do_constant_folding=True,  # whether to execute constant folding for optimization 
        input_names = ['input'],   # the model's input names 
        output_names = ['output'], # the model's output names 
        dynamic_axes={'input' : {0 : 'batch_size'},    # variable length axes 
                            'output' : {0 : 'batch_size'}}) 