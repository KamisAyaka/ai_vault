# 🏗 AI Vault 项目

基于 [Scaffold-ETH 2](https://scaffoldeth.io) 构建的智能 DeFi 资产管理平台

<h4 align="center">
  <a href="https://docs.scaffoldeth.io">Scaffold-ETH 文档</a> |
  <a href="DEVELOPMENT.md">开发文档</a>
</h4>


## 🚀 AI Vault 项目概述

AI Vault 是一个基于 Scaffold-ETH 2 构建的去中心化金融（DeFi）项目，旨在为用户提供智能资产管理服务。该项目通过 AI 代理管理投资策略，将资金分配到不同的 DeFi 协议中以获取收益。

### 核心特性

- 💰 **智能金库管理**: 基于 ERC-4626 标准的份额化投资金库
- 🤖 **AI 代理控制**: 由 AI 代理自动管理投资策略和资产分配
- 🔄 **多协议支持**: 集成 Aave、Uniswap V2/V3 等主流 DeFi 协议
- 💎 **ETH 支持**: 支持 ETH 和 WETH 的直接存款和转换
- 🛡️ **安全保障**: 防重入攻击、权限控制和参数验证
- 📊 **实时监控**: 完整的测试套件和集成测试

### 技术栈

⚙️ 使用 NextJS、RainbowKit、Foundry、Wagmi、Viem 和 Typescript 构建

- ✅ **合约热重载**: 前端会在你编辑智能合约时自动适配
- 🪝 **[自定义钩子](https://docs.scaffoldeth.io/hooks/)**: 围绕 [wagmi](https://wagmi.sh/) 的 React 钩子集合
- 🧱 [**组件**](https://docs.scaffoldeth.io/components/): 常见 web3 组件集合
- 🔥 **燃烧钱包和本地水龙头**: 快速测试应用程序
- 🔐 **钱包提供商集成**: 连接不同钱包提供商

## 系统要求

在开始之前，你需要安装以下工具：

- [Node (>= v20.18.3)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) 或 [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

## 快速开始

要开始使用 Scaffold-ETH 2 和 AI Vault 项目，请按照以下步骤操作：

### 1. 安装依赖

```bash
git clone https://github.com/KamisAyaka/ai_vault.git
cd ai_vault
yarn install
```

### 2. 启动本地网络

在第一个终端中运行：

```bash
yarn chain
```

此命令使用 Foundry 启动本地以太坊网络。网络在你的本地机器上运行，可用于测试和开发。你可以在 `packages/foundry/foundry.toml` 中自定义网络配置。

### 3. 部署 AI Vault 合约

在第二个终端中，部署 AI Vault 系统：

```bash
# 部署完整的 AI Vault 系统
yarn deploy --file DeployAIVault.s.sol

# 或者部署基础测试合约
yarn deploy
```

此命令将 AI Vault 智能合约部署到本地网络。合约位于 `packages/foundry/contracts` 中，可以根据需要进行修改。`yarn deploy` 命令使用位于 `packages/foundry/script` 的部署脚本来将合约部署到网络。

### 4. 启动前端应用

在第三个终端中，启动你的 NextJS 应用：

```bash
yarn start
```


访问你的应用：`http://localhost:3000`。你可以使用 `Debug Contracts` 页面与你的智能合约交互。你可以在 `packages/nextjs/scaffold.config.ts` 中调整应用配置。

## 📚 了解更多

### 系统架构和工作原理

要深入了解 AI Vault 的系统架构、核心组件、工作流程等技术细节，请查看 [DEVELOPMENT.md](DEVELOPMENT.md)

### Scaffold-ETH 2 文档

访问 [Scaffold-ETH 2 文档](https://docs.scaffoldeth.io)了解更多开发功能和最佳实践。

## 📄 许可证

本项目基于 MIT 许可证开源。

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue：[GitHub Issues](https://github.com/your-repo/issues)
- 讨论交流：[GitHub Discussions](https://github.com/your-repo/discussions)

---

**注意**：本项目仍在开发中，请在生产环境使用前进行充分测试。
