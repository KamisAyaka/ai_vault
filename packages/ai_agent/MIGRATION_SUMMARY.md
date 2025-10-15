# Flask to Vercel + Supabase 迁移总结

## 主要变更

### 1. 数据库层改造

**文件**: `persistence_layer/database.py`

**变更内容**:
- 移除 `psycopg2` 和 PostgreSQL 直接连接
- 引入 `supabase-py` 客户端
- 所有数据库操作改用 Supabase API
- 保持了相同的接口，使上层代码无需修改

**主要差异**:
```python
# 旧方式 (psycopg2)
with get_db_connection() as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM table WHERE ...")

# 新方式 (Supabase)
response = supabase.table('table').select('*').eq('column', value).execute()
```

### 2. API 层重构

**旧结构**: `analytics_layer/analytics_api.py` (单一 Flask 应用)

**新结构**: `api/` 目录下的独立函数
```
api/
├── __init__.py
├── _utils.py              # 通用工具函数
├── _data_helper.py        # 数据获取辅助函数
├── health.py              # 健康检查
├── net_value_curve.py     # 净值曲线
├── performance.py         # 性能指标
├── allocation_history.py  # 配置历史
├── simulator.py           # 回测模拟器
└── summary.py             # 综合概览
```

**每个 API 函数的标准结构**:
```python
def handler(event, context):
    """处理 Vercel Serverless Function 请求"""
    try:
        # 解析参数
        params = parse_query_params(event)

        # 业务逻辑
        result = do_something(params)

        # 返回成功响应
        return success_response(result)
    except Exception as e:
        # 返回错误响应
        return error_response(str(e))
```

### 3. 路由映射

**旧方式** (Flask):
```python
@app.route('/api/v1/analytics/health', methods=['GET'])
def health_check():
    # ...
```

**新方式** (vercel.json):
```json
{
  "routes": [
    {
      "src": "/api/health",
      "dest": "/api/health.py"
    }
  ]
}
```

### 4. 依赖更新

**requirements.txt 变更**:
```diff
- psycopg2-binary>=2.9.9
- sqlalchemy>=2.0.0
- flask>=3.0.0
- flask-cors>=4.0.0
- gunicorn>=21.2.0
+ supabase>=2.0.0
+ postgrest>=0.10.0
```

### 5. 环境变量

**旧方式**:
```env
DATABASE_URL=postgresql://user:pass@host:5432/db
```

**新方式**:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_supabase_anon_key
```

## API 端点对照表

| 旧端点 (Flask) | 新端点 (Vercel) | 方法 | 文件 |
|---------------|----------------|------|------|
| `/api/v1/analytics/health` | `/api/health` | GET | `api/health.py` |
| `/api/v1/analytics/net-value-curve` | `/api/net_value_curve` | GET | `api/net_value_curve.py` |
| `/api/v1/analytics/performance` | `/api/performance` | GET | `api/performance.py` |
| `/api/v1/analytics/allocation-history` | `/api/allocation_history` | GET | `api/allocation_history.py` |
| `/api/v1/analytics/simulator` | `/api/simulator` | POST | `api/simulator.py` |
| `/api/v1/analytics/summary` | `/api/summary` | GET | `api/summary.py` |

## 保持不变的部分

以下文件**无需修改**，保持原样：

1. `analytics_layer/analytics_engine.py` - 分析引擎逻辑
2. `ai_layer/` - AI 策略系统
3. `data_layer/` - 数据获取层
4. `execution_layer/` - 执行层
5. 其他业务逻辑文件

## 部署流程对比

### 旧方式 (传统服务器)
```bash
# 启动 Flask 服务器
python analytics_api.py

# 或使用 gunicorn
gunicorn -w 4 -b 0.0.0.0:8001 analytics_api:app
```

### 新方式 (Vercel)
```bash
# 本地开发
vercel dev

# 部署到生产环境
vercel --prod
```

## 优势

### 使用 Vercel + Supabase 的好处：

1. **自动扩展**: 无需管理服务器，自动处理流量波动
2. **全球 CDN**: Vercel 的边缘网络确保低延迟
3. **零运维**: 不需要维护数据库服务器
4. **成本优化**: 按使用付费，闲置时几乎零成本
5. **内置 HTTPS**: 自动 SSL 证书
6. **实时数据库**: Supabase 提供实时订阅功能
7. **备份和恢复**: Supabase 自动备份
8. **开发体验**: 更快的部署和迭代

## 迁移检查清单

- [x] 改造 database.py 使用 Supabase
- [x] 创建 Vercel Serverless Functions 结构
- [x] 将 Flask 路由拆分为独立函数
- [x] 更新 requirements.txt
- [x] 创建 vercel.json 配置
- [x] 创建部署文档
- [ ] 在 Supabase 创建数据库表
- [ ] 设置 Vercel 环境变量
- [ ] 测试所有 API 端点
- [ ] 更新前端 API 调用地址

## 需要前端更新的地方

如果你的前端调用了这些 API，需要更新 API 基础 URL：

```javascript
// 旧方式
const API_BASE = 'http://localhost:8001/api/v1/analytics'

// 新方式
const API_BASE = 'https://your-project.vercel.app/api'
```

## 测试建议

部署后建议测试以下场景：

1. **健康检查**: `GET /api/health`
2. **数据获取**: `GET /api/summary?pool=wBTC-USDC`
3. **性能指标**: `GET /api/performance?period=ALL`
4. **回测模拟**: `POST /api/simulator` (带正确的请求体)
5. **缓存功能**: 多次调用相同端点，验证缓存是否生效

## 故障排查

如果遇到问题，请检查：

1. Vercel 函数日志：`vercel logs`
2. Supabase 数据库连接：确认 URL 和 Key 正确
3. 表结构：确保所有表都已创建
4. 环境变量：在 Vercel Dashboard 中验证
5. Python 依赖：确认 requirements.txt 中的版本兼容

## 回滚计划

如果需要回滚到 Flask 版本：

1. 恢复 `analytics_api.py` 文件
2. 恢复 `database.py` 的 psycopg2 版本
3. 恢复 requirements.txt
4. 重新部署到传统服务器

原始文件已保留，可以通过 git 历史恢复。
