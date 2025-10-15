# 快速开始指南

### 步骤 1: 准备 Supabase 数据库

1. 访问 [https://supabase.com](https://supabase.com) 并登录
2. 创建新项目，等待初始化完成
3. 打开 SQL Editor，复制粘贴以下 SQL 并执行：

```sql
-- 创建表
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

CREATE TABLE performance_cache (
    pool_symbol TEXT NOT NULL,
    period TEXT NOT NULL,
    metrics JSONB NOT NULL,
    calculated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY(pool_symbol, period)
);

CREATE INDEX idx_pool_snapshots_timestamp ON pool_snapshots(timestamp);
CREATE INDEX idx_strategy_executions_timestamp ON strategy_executions(timestamp);
```

4. 获取连接信息：
   - 项目设置 → API → URL (复制保存)
   - 项目设置 → API → anon public key (复制保存)

### 步骤 2: 部署到 Vercel 

### 步骤 3: 测试 API

部署完成后，你会获得一个 URL，例如 `https://your-project.vercel.app`

测试健康检查：
```bash
curl https://your-project.vercel.app/api/health
```

应该返回：
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2024-01-01T00:00:00",
    "service": "DeFi Analytics API",
    "database": "connected",
    "stats": { ... }
  }
}
```

## 本地开发

### 安装依赖

```bash
cd packages/ai_agent
pip install -r requirements.txt
```

### 配置环境变量

创建 `.env` 文件：
```bash
cp .env.example .env
```

编辑 `.env` 填入你的 Supabase 凭据：
```env
SUPABASE_URL="https://your-project.supabase.co"
SUPABASE_KEY="your_supabase_anon_key"
```

### 启动本地开发服务器

```bash
vercel dev
```

访问 `http://localhost:3000/api/health` 测试

## API 端点

所有端点都已部署，可以直接使用：

```bash
# 健康检查
GET /api/health

# 综合概览
GET /api/summary?pool=wBTC-USDC

# 净值曲线
GET /api/net_value_curve?pool=wBTC-USDC&hours=720

# 性能指标
GET /api/performance?pool=wBTC-USDC&period=ALL

# 配置历史
GET /api/allocation_history?pool=wBTC-USDC&hours=720

# 回测模拟器
POST /api/simulator
Content-Type: application/json
{
  "pool_symbol": "wBTC-USDC",
  "user_allocations": [
    {
      "timestamp": "2024-01-01T00:00:00",
      "aave_wbtc_pool": 0.7,
      "uniswap_v3_lp": 0.3
    }
  ]
}
```

## 前端集成

在你的前端代码中使用：

```javascript
const API_BASE = 'https://your-project.vercel.app/api'

// 获取概览
async function getSummary() {
  const response = await fetch(`${API_BASE}/summary?pool=wBTC-USDC`)
  const data = await response.json()
  return data
}

// 获取净值曲线
async function getNetValueCurve(hours = 720) {
  const response = await fetch(`${API_BASE}/net_value_curve?pool=wBTC-USDC&hours=${hours}`)
  const data = await response.json()
  return data
}
```

## 常见问题

### Q: 部署失败，提示找不到模块？
A: 确保 `requirements.txt` 包含所有必要的依赖，并且 Vercel 能访问到它。

### Q: API 返回 500 错误？
A: 检查 Vercel 函数日志：`vercel logs`，通常是环境变量未设置或数据库连接问题。

### Q: 如何查看日志？
A: 使用 `vercel logs` 命令，或在 Vercel Dashboard 中查看。

### Q: 如何更新部署？
A: 只需推送代码到 Git 仓库，Vercel 会自动重新部署。

### Q: 可以使用自定义域名吗？
A: 可以！在 Vercel 项目设置中添加自定义域名。

## 下一步

- 查看 [DEPLOYMENT.md](./DEPLOYMENT.md) 了解详细部署说明
- 查看 [MIGRATION_SUMMARY.md](./MIGRATION_SUMMARY.md) 了解架构变更
- 开始向数据库导入历史数据
- 配置定时任务更新数据
- 集成到你的前端应用

## 需要帮助？

- [Vercel 文档](https://vercel.com/docs)
- [Supabase 文档](https://supabase.com/docs)
- [项目 Issues](../../issues)
