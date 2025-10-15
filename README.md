# 🏗 AI Vault Project

A smart DeFi asset management platform built on [Scaffold-ETH 2](https://scaffoldeth.io)

<h4 align="center">
  <a href="https://docs.scaffoldeth.io">Scaffold-ETH Documentation</a> |
  <a href="DEVELOPMENT_EN.md">Development Documentation</a>
</h4>


## 🚀 AI Vault Project Overview

AI Vault is a decentralized finance (DeFi) project built on Scaffold-ETH 2, designed to provide users with intelligent asset management services. The project uses AI agents to manage investment strategies and allocate funds to different DeFi protocols to generate returns.

### Core Features

- 💰 **Smart Vault Management**: Share-based investment vaults based on ERC-4626 standard
- 🤖 **AI Agent Control**: AI agents automatically manage investment strategies and asset allocation
- 🔄 **Multi-protocol Support**: Integrates mainstream DeFi protocols like Aave, Uniswap V2/V3
- 💎 **ETH Support**: Direct deposit and conversion support for ETH and WETH
- 🛡️ **Security Assurance**: Reentrancy attack protection, access control, and parameter validation
- 📊 **Real-time Monitoring**: Complete test suite and integration tests

### Tech Stack

⚙️ Built with NextJS, RainbowKit, Foundry, Wagmi, Viem and Typescript

- ✅ **Contract Hot Reload**: Frontend automatically adapts when you edit smart contracts
- 🪝 **[Custom Hooks](https://docs.scaffoldeth.io/hooks/)**: Collection of React hooks around [wagmi](https://wagmi.sh/)
- 🧱 [**Components**](https://docs.scaffoldeth.io/components/): Collection of common web3 components
- 🔥 **Burner Wallet and Local Faucet**: Quick testing of applications
- 🔐 **Wallet Provider Integration**: Connect different wallet providers

## System Requirements

Before starting, you need to install the following tools:

- [Node (>= v20.18.3)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

## Quick Start

To get started with Scaffold-ETH 2 and the AI Vault project, follow these steps:

### 1. Install Dependencies

```bash
git clone https://github.com/KamisAyaka/ai_vault.git
cd ai_vault
yarn install
```

### 2. Start Local Network

Run in the first terminal:

```bash
yarn chain
```

This command starts a local Ethereum network using Foundry. The network runs on your local machine and can be used for testing and development. You can customize the network configuration in `packages/foundry/foundry.toml`.

### 3. Deploy AI Vault Contracts

In the second terminal, deploy the AI Vault system:

```bash
# Deploy complete AI Vault system
yarn deploy --file DeployAIVault.s.sol

# Or deploy basic test contracts
yarn deploy
```

This command deploys the AI Vault smart contracts to the local network. The contracts are located in `packages/foundry/contracts` and can be modified as needed. The `yarn deploy` command uses deployment scripts located in `packages/foundry/script` to deploy contracts to the network.

### 4. Start Frontend Application

In the third terminal, start your NextJS application:

```bash
yarn start
```


Visit your application: `http://localhost:3000`. You can use the `Debug Contracts` page to interact with your smart contracts. You can adjust application configuration in `packages/nextjs/scaffold.config.ts`.

## 📚 Learn More

### System Architecture and Working Principles

To learn more about the technical details of AI Vault's system architecture, core components, workflow, etc., please check [DEVELOPMENT_EN.md](DEVELOPMENT_EN.md)

### Scaffold-ETH 2 Documentation

Visit [Scaffold-ETH 2 Documentation](https://docs.scaffoldeth.io) to learn more about development features and best practices.

## 📄 License

This project is open source under the MIT license.

## 📞 Contact

For questions or suggestions, please contact through:

- Submit Issues: [GitHub Issues](https://github.com/your-repo/issues)
- Discussion: [GitHub Discussions](https://github.com/your-repo/discussions)

---

**Note**: This project is still under development, please conduct thorough testing before using in production.
