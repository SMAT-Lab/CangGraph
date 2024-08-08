import os
from transformers import AutoTokenizer, AutoModel
# 加载预训练的 BERT 模型和 tokenizer
import warnings
warnings.filterwarnings('ignore')

model_name = "bert-base-uncased"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModel.from_pretrained(model_name)

from pinecone import Pinecone
import json
import torch
import pandas as pd

# 初始化 Pinecone
pc = Pinecone(api_key="40075f49-8396-4571-924a-4b6d342cc81d")

# 创建 Pinecone 索引
index_name = "example-index"
dimension = 768  # BERT base 的输出维度是 768
# 连接到索引
index = pc.Index(index_name)

# 定义生成嵌入向量的函数
def get_embedding(text):
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True)
    outputs = model(**inputs)
    # 使用最后一个隐藏层的平均池化作为句子嵌入
    embeddings = outputs.last_hidden_state.mean(dim=1).squeeze().detach().numpy()
    return embeddings

from openai import OpenAI
import httpx 
import requests
from openai import OpenAI


def generate(message, model='arktsLLM') -> None:
    client = OpenAI(
        base_url='http://localhost:11434/v1/',
        api_key='ollama',
    )

    chat_completion = client.chat.completions.create(
        messages=
        [
            {
                'role': 'system',
                'content': '你是arkts代码修复专家，根据用户给出的错误代码以及问题类型，帮助用户修复代码。'
            },
            {
                'role': 'user',
                'content': message
            }
        ],
        model=model,
        temperature=0
    )

    return chat_completion.choices[0].message.content

# 查询示例
import pandas as pd

from pinecone import Pinecone
import json
import torch

# 初始化 Pinecone
pc = Pinecone(api_key="40075f49-8396-4571-924a-4b6d342cc81d")

# 创建 Pinecone 索引
index_name = "example-index"
dimension = 768  # BERT base 的输出维度是 768
# 连接到索引
index = pc.Index(index_name)

# 定义生成嵌入向量的函数
def get_embedding(text):
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True)
    outputs = model(**inputs)
    # 使用最后一个隐藏层的平均池化作为句子嵌入
    embeddings = outputs.last_hidden_state.mean(dim=1).squeeze().detach().numpy()
    return embeddings

def add_vectors(data):
    # 将文本数据转换为嵌入向量并插入到 Pinecone 中
    texts = []
    for item in data:
        text = json.dumps(item)
        # print(text)
        texts.append(text)

    # print(texts)
    vectors = [{"id": str(text_id), "values": get_embedding(text), "metadata": {"text": text, "rule": json.loads(text)['rule']}} for text_id, text in enumerate(texts)]
    index.upsert(vectors, namespace="arkts")

# add_vectors()


# 读取Excel文件，指定没有表头
df_input = pd.read_excel('../data/test.xlsx', header=None)

# 遍历每一行并格式化输出
test = []
for i, row in df_input.iterrows():
    if i == 0:
        continue
    row[0] = row[0].strip()

    item = {
        "rule": row[0],
        "description": row[1],
        "problem_code": row[2],
    }

    test.append(item)

for i in range(len(test)):
    query_text = json.dumps(test[i])

    query_vector = get_embedding(query_text)
    # 检索最相似的向量
    results = index.query(namespace="arkts", vector=query_vector.tolist(), top_k=5, include_metadata=True,
        filter={"rule": test[i]["rule"]})

    prompt = "下面我将给出你类似的错误，请根据这些错误的修复方案，帮我修复一下我的代码。\n"
    matches = results.matches
    for j, match in enumerate(matches):
        # print(f"ID: {match.id}, Score: {match.score}")
        metadata_text = match['metadata']['text']
        try:
            parsed_text = json.loads(metadata_text)
            prompt += f"Demo {j+1}: \nRule: \n{parsed_text['rule']}\nDescription: \n{parsed_text['description']}\nProblem Code: \n{parsed_text['problem_code']}\n\nProblem explain: \n{parsed_text['problem_explain']}\n\nProblem Fix: \n{parsed_text['problem_fix']}\n\n"
        except json.JSONDecodeError as e:
            print(f"Error decoding JSON for ID {match['id']}: {e}")
            print(f"Original metadata text: {metadata_text}")

    print(prompt)
    prompt += f"下面开始错误的修复！\n我有如下代码：\n{test[i]['problem_code']}\n对应的问题类型是: {test[i]['rule']}\n该问题类型的描述如下:{test[i]['description']}\n请您帮我修复一下: ```arkts\n"
    res = generate(prompt)
    print('---------')
    print(test[i]['problem_code'])
    print('---------')
    print(res)