# Vercel + Supabase 部署指南

本项目已改造为适合 Vercel Serverless Functions + Supabase 的架构。

## 项目结构

```
packages/ai_agent/
├── api/                          # Vercel Serverless Functions
│   ├── _utils.py                 # 通用工具函数
│   ├── _data_helper.py           # 数据获取辅助函数
│   ├── health.py                 # GET /api/health
│   ├── net_value_curve.py        # GET /api/net_value_curve
│   ├── performance.py            # GET /api/performance
│   ├── allocation_history.py     # GET /api/allocation_history
│   ├── simulator.py              # POST /api/simulator
│   └── summary.py                # GET /api/summary
├── persistence_layer/
│   └── database.py               # 改为使用 Supabase 客户端
├── vercel.json                   # Vercel 配置文件
├── requirements.txt              # Python 依赖（已添加 supabase）
└── DEPLOYMENT.md                 # 本文档
```

## 部署步骤

### 1. 准备 Supabase 数据库

1. 访问 [https://supabase.com](https://supabase.com) 创建项目
2. 在 Supabase 项目中创建以下表：

```sql
-- 池子快照表
CREATE TABLE pool_snapshots (
    id BIGSERIAL PRIMARY KEY,
    pool_symbol TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    wbtc_price NUMERIC,
    volume_usd NUMERIC,
    liquidity NUMERIC,
    tvl_usd NUMERIC,
    aave_wbtc_apy NUMERIC,
    univ3_lp_apy NUMERIC,
    gas_cost_usd NUMERIC,
    UNIQUE(pool_symbol, timestamp)
);

-- 策略执行表
CREATE TABLE strategy_executions (
    id BIGSERIAL PRIMARY KEY,
    pool_symbol TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    aave_wbtc_pool NUMERIC,
    uniswap_v3_lp NUMERIC,
    tx_hash TEXT,
    model_confidence NUMERIC,
    safety_bounds JSONB,
    additional_info JSONB
);

-- 性能缓存表
CREATE TABLE performance_cache (
    pool_symbol TEXT NOT NULL,
    period TEXT NOT NULL,
    metrics JSONB NOT NULL,
    calculated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY(pool_symbol, period)
);

-- 创建索引
CREATE INDEX idx_pool_snapshots_timestamp ON pool_snapshots(timestamp);
CREATE INDEX idx_strategy_executions_timestamp ON strategy_executions(timestamp);
```

3. 获取 Supabase 连接信息：
   - 项目设置 -> API -> URL（SUPABASE_URL）
   - 项目设置 -> API -> anon public key（SUPABASE_KEY）

### 2. 部署到 Vercel

#### 方式一：通过 Vercel CLI

```bash
# 安装 Vercel CLI
npm i -g vercel

# 进入项目目录
cd packages/ai_agent

# 登录 Vercel
vercel login

# 设置环境变量
vercel env add SUPABASE_URL
vercel env add SUPABASE_KEY

# 部署
vercel --prod
```

#### 方式二：通过 Vercel Dashboard

1. 访问 [https://vercel.com](https://vercel.com)
2. 导入 Git 仓库
3. 设置根目录为 `packages/ai_agent`
4. 在环境变量中添加：
   - `SUPABASE_URL`: 你的 Supabase URL
   - `SUPABASE_KEY`: 你的 Supabase anon key
5. 点击部署

### 3. 验证部署

部署成功后，访问以下端点测试：

```bash
# 健康检查
curl https://your-project.vercel.app/api/health

# 获取概览
curl https://your-project.vercel.app/api/summary?pool=wBTC-USDC

# 获取净值曲线
curl https://your-project.vercel.app/api/net_value_curve?pool=wBTC-USDC&hours=720
```

## API 端点

| 端点 | 方法 | 描述 |
|------|------|------|
| `/api/health` | GET | 健康检查 |
| `/api/summary` | GET | 综合概览 |
| `/api/net_value_curve` | GET | 获取净值曲线 |
| `/api/performance` | GET | 获取性能指标 |
| `/api/allocation_history` | GET | 获取配置历史 |
| `/api/simulator` | POST | 运行回测模拟器 |

## 环境变量

必需的环境变量：

- `SUPABASE_URL`: Supabase 项目 URL
- `SUPABASE_KEY`: Supabase anon public key

## 注意事项

1. **数据库改造**：已将 `psycopg2` 改为 `supabase-py` 客户端
2. **Flask 移除**：不再使用 Flask，改为 Vercel Serverless Functions
3. **路由配置**：在 `vercel.json` 中配置路由映射
4. **环境变量**：确保在 Vercel Dashboard 中正确设置环境变量
5. **Python 版本**：Vercel 默认使用 Python 3.9，可在 `vercel.json` 中指定版本

## 本地开发

```bash
# 安装依赖
pip install -r requirements.txt

# 设置环境变量
export SUPABASE_URL="your_supabase_url"
export SUPABASE_KEY="your_supabase_key"

# 使用 Vercel CLI 本地开发
vercel dev
```

## 故障排查

如果遇到问题：

1. 检查 Vercel 函数日志
2. 确认环境变量是否正确设置
3. 确认 Supabase 数据库表已创建
4. 检查 API 路径是否与 `vercel.json` 配置一致

## 从 Flask 迁移说明

主要变更：

1. **数据库连接**：从 `psycopg2` 改为 `supabase-py`
2. **路由处理**：从 Flask 路由改为独立的 handler 函数
3. **响应格式**：使用自定义的 `json_response` 函数
4. **部署方式**：从传统服务器部署改为 Serverless 部署

## 更多资源

- [Vercel Python 文档](https://vercel.com/docs/functions/serverless-functions/runtimes/python)
- [Supabase Python 文档](https://supabase.com/docs/reference/python/introduction)
