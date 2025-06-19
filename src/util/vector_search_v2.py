from pinecone import Pinecone
from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
from typing import List, Optional, Dict, Any
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, resources={
    r"/v2/search": {
        "origins": ["http://211.71.15.50", "https://211.71.15.50"],
        "methods": ["POST"],
        "allow_headers": ["Content-Type"]
    }
})

class VectorSearchError(Exception):
    """向量搜索自定义异常类"""
    pass

def validate_vector(vector: List[float]) -> bool:
    """
    验证向量格式是否正确
    
    Args:
        vector: 输入向量
        
    Returns:
        bool: 验证是否通过
    """
    if not isinstance(vector, list):
        return False
    if len(vector) != 384:  # 确保向量维度正确
        return False
    return all(isinstance(x, (int, float)) for x in vector)

def init_pinecone() -> Pinecone:
    """
    初始化 Pinecone 客户端
    
    Returns:
        Pinecone: Pinecone客户端实例
        
    Raises:
        VectorSearchError: 初始化失败时抛出
    """
    try:
        return Pinecone(
            api_key="pcsk_7FJ53n_A2REvKqbYS5A2mqnXi2m97NT4dVCi4oLN5VEdyp1NFBPhshic7b8fkNT6BJSEkX"
        )
    except Exception as e:
        logger.error(f"Pinecone 初始化失败: {str(e)}")
        raise VectorSearchError("向量搜索服务初始化失败")

def process_search_results(results: Dict[str, Any]) -> List[Dict[str, Any]]:
    """
    处理搜索结果
    
    Args:
        results: Pinecone查询返回的原始结果
        
    Returns:
        List[Dict[str, Any]]: 处理后的结果列表
    """
    processed_results = []
    for match in results['matches']:
        processed_match = {
            'id': match['id'],
            'score': round(float(match['score']), 4),
            'metadata': match.get('metadata', {})
        }
        processed_results.append(processed_match)
    return processed_results

@app.route('/v2/search', methods=['POST'])
def search_v2():
    """
    向量搜索API V2版本
    支持自定义top_k参数和更好的错误处理
    """
    try:
        # 获取请求数据
        data = request.get_json()
        if not data:
            return jsonify({
                'success': False,
                'error': '无效的请求数据'
            }), 400

        # 验证必需参数
        if 'vector' not in data:
            return jsonify({
                'success': False,
                'error': '请求必须包含向量数据'
            }), 400

        # 验证向量
        vector = data['vector']
        if not validate_vector(vector):
            return jsonify({
                'success': False,
                'error': '向量格式不正确，必须是384维的数值数组'
            }), 400

        # 获取和验证可选参数
        top_k = data.get('top_k', 3)
        if not isinstance(top_k, int) or top_k < 1 or top_k > 100:
            return jsonify({
                'success': False,
                'error': 'top_k 必须是1-100之间的整数'
            }), 400

        # 初始化 Pinecone
        pc = init_pinecone()
        index = pc.Index("python-defects")

        # 执行查询
        result = index.query(
            vector=vector,
            top_k=top_k,
            include_metadata=True,
            include_values=False
        )

        # 处理结果
        processed_results = process_search_results(result)
        
        # 记录成功查询
        logger.info(f"成功执行查询，返回 {len(processed_results)} 条结果")

        return jsonify({
            'success': True,
            'data': {
                'matches': processed_results,
                'total': len(processed_results)
            }
        })

    except VectorSearchError as e:
        logger.error(f"向量搜索错误: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
    except Exception as e:
        logger.error(f"未预期的错误: {str(e)}")
        return jsonify({
            'success': False,
            'error': '服务器内部错误'
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5050)  # 使用不同的端口避免冲突 