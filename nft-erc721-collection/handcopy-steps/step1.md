# 阶段一：项目骨架与配置

**目标**：搭好 monorepo 与 smart-contract 骨架，能 `yarn`、`yarn compile`，配置作为唯一真相源。

**验收**：根目录与 `smart-contract` 下 `yarn`、`yarn compile` 通过；配置与占位合约无 TypeScript/Solidity 报错。

---

## 一、根目录

- 新建 `package.json`：保留 `name`、`description` 等；`scripts` 中可有 `build-dapp`（先不跑也可，等 DAPP 阶段再加）。
- 在项目根目录执行 `yarn`（或 `npm install`）。

---

## 二、智能合约子项目目录

创建目录 `smart-contract/`，以下文件均在该目录下。

---

## 三、合约项目 package 与 TypeScript

- **smart-contract/package.json**：从原项目复制，保留 hardhat、ethers、@openzeppelin/contracts、erc721a、dotenv、ts-node、typescript、merkletreejs、keccak256 等；scripts 先保留 `compile`、`accounts` 即可。
- **smart-contract/tsconfig.json**：从原项目复制，保证与 Hardhat 兼容。
- **smart-contract/.gitignore**：含 `node_modules`、`artifacts`、`cache`、`.env`。
- **smart-contract/.env-sample**：从本仓库复制或根据实际 `.env` 导出模板，列出 `DEPLOYER_PRIVATE_KEY`、`NETWORK_TESTNET_URL`、`NETWORK_TESTNET_PRIVATE_KEY`、`NETWORK_MAINNET_*`、`BLOCK_EXPLORER_API_KEY`、`COLLECTION_URI_PREFIX` 等，值为空或占位；本地使用时复制为 `.env` 并填入真实值。**DEPLOYER_PRIVATE_KEY** 为部署与各脚本（deploy、whitelist-open、reveal 等）所用私钥，必填。

在 `smart-contract` 下执行 `yarn`。

---

## 四、Hardhat 配置（先精简版）

- **smart-contract/hardhat.config.ts**：先写 `import * as dotenv from 'dotenv'; dotenv.config();`、`solidity` 版本与 optimizer、`networks` 里 `hardhat` 默认；先不写自定义 task，不导入 `CollectionConfig`。

验收：在 `smart-contract` 下执行 `yarn hardhat compile` 应能跑（没有合约会报错，下一步再加占位合约）。

---

## 五、配置相关接口（lib）

- **smart-contract/lib/NetworkConfigInterface.ts**：定义 chainId、symbol、blockExplorer（name、generateContractUrl、generateTransactionUrl）。
- **smart-contract/lib/MarketplaceConfigInterface.ts**：定义 name、generateCollectionUrl。
- **smart-contract/lib/CollectionConfigInterface.ts**：定义 testnet、mainnet、contractName、tokenName、tokenSymbol、hiddenMetadataUri、maxSupply、whitelistSale/preSale/publicSale（price、maxMintAmountPerTx）、contractAddress、marketplaceIdentifier、marketplaceConfig、whitelistAddresses。

---

## 六、网络与市场配置实现

- **smart-contract/lib/Networks.ts**：从原项目复制 hardhatLocal、ethereumTestnet、ethereumMainnet、polygonTestnet、polygonMainnet 等（实现 `NetworkConfigInterface`）。
- **smart-contract/lib/Marketplaces.ts**：从原项目复制 OpenSea 的 generateCollectionUrl 等（实现 `MarketplaceConfigInterface`）。

---

## 七、集合配置与部署参数

- **smart-contract/config/whitelist.json**：数组格式，如 `["0x...", "0x..."]`，可先填 2～3 个测试地址。**若希望用本机 MetaMask 账号做白名单铸造验证**：在 `.env` 中配置好 `DEPLOYER_PRIVATE_KEY` 后，把该私钥对应的地址（即你的 MetaMask 地址）追加到 `whitelist.json` 末尾，这样部署并开启白名单后即可用该账号在前端或区块浏览器完成 whitelist mint 自测。
- **smart-contract/config/CollectionConfig.ts**：从原项目复制并按需改 testnet/mainnet、contractName（与合约名一致）、tokenName、tokenSymbol、hiddenMetadataUri、maxSupply、whitelistSale/preSale/publicSale、contractAddress: null、marketplaceIdentifier、marketplaceConfig、whitelistAddresses 引入。
- **smart-contract/config/ContractArguments.ts**：从原项目复制，用 `CollectionConfig` 拼出构造函数参数数组（tokenName、tokenSymbol、price 用 parseEther、maxSupply、maxMintAmountPerTx、hiddenMetadataUri）。

---

## 八、占位合约（保证能 compile）

- **smart-contract/contracts/YourNftToken.sol**：最小实现——`pragma solidity ^0.8.9;`、继承 `ERC721`（OpenZeppelin）或 `ERC721A`、constructor(name, symbol) 及与 `ContractArguments` 一致的参数（若用 6 个参数：name, symbol, cost, maxSupply, maxMintPerTx, hiddenUri）；空 body 或仅 `_safeMint` 占位。

执行：

```bash
cd smart-contract
yarn compile
```

验收：无报错，生成 `artifacts/` 和 `cache/`。

---

## 九、阶段一总验收清单

- [ ] 根目录 `yarn` 成功
- [ ] `smart-contract` 下 `yarn`、`yarn compile` 成功
- [ ] `CollectionConfig`、`ContractArguments`、`Networks`、`Marketplaces` 无 TypeScript 报错
- [ ] 占位合约构造函数参数与 `ContractArguments.ts` 一致
