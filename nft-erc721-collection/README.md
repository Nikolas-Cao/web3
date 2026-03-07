# NFT ERC721 合集

本项目基于 [foundry-nft-erc721-collection](https://github.com/hashlips-lab/nft-erc721-collection) 的演示项目。

> 如有任何侵权行为，请联系我删除。

---

## 目录

- [介绍](#介绍)
- [核心概念](#核心概念)
- [铸造方式](#铸造方式)
- [典型项目流程](#典型项目流程)
- [流程小结](#流程小结)
- [如何学习手抄该项目](#如何学习手抄该项目)
- [注意事项](#注意事项)

---

## 介绍

基于 **ERC721A** 的 NFT 合约，支持：

- 白名单（Merkle 校验）
- 公开铸造
- 隐藏元数据（Reveal 盲盒）
- 暂停控制

---

## 核心概念

| 概念 | 说明 |
|------|------|
| **ERC721AQueryable** | 继承 ERC721A，支持按所有者查询 token，节省 gas |
| **Merkle 白名单** | 用 `merkleRoot` + `_merkleProof` 校验地址是否在白名单，每人只能 `whitelistMint` 一次（`whitelistClaimed`） |
| **hiddenMetadataUri** | 未 reveal 时，所有 token 的 `tokenURI()` 都返回该「占位图/盲盒」URI |
| **revealed** | 为 `true` 后，`tokenURI()` 改为返回 `uriPrefix + tokenId + uriSuffix`（真实元数据） |
| **paused** | 为 `true` 时禁止公开 `mint()`，白名单铸造不受影响 |
| **cost** | 每次铸造需支付的 ETH（可后续由 owner 修改） |

---

## 铸造方式

1. **whitelistMint**  
   需白名单开启、未领过、Merkle 校验通过，并支付 `cost × _mintAmount`。

2. **mint**  
   公开铸造，需合约未暂停，并支付 `cost × _mintAmount`。

3. **mintForAddress**  
   仅 owner 可调用，免费为指定地址铸造，用于预留/合作方等。

---

## 典型项目流程

按时间顺序的典型「项目」流程如下。

### 1. 部署合约

- 使用 `CollectionConfig` 中的参数（名称、符号、初始 cost、maxSupply、每笔最大数量、hiddenMetadataUri）部署。
- 部署时 `paused = true`、`whitelistMintEnabled = false`、`revealed = false`：  
  即先不能公开买，也不能白名单买，且所有人看到的都是「盲盒」图。

### 2. 配置白名单并开启白名单售卖

- 生成 Merkle Root：用 `whitelist.json` 里的地址列表（或你替换后的真实名单）生成 Merkle 树，得到 `merkleRoot`。
- 调用 `setMerkleRoot(merkleRoot)` 写入合约。
- （可选）若白名单阶段想用不同价格/数量，可调用 `setCost`、`setMaxMintAmountPerTx`，再 `setWhitelistMintEnabled(true)`。
- 用户在前端用自己地址 + 后端/脚本生成的 Merkle Proof 调用 `whitelistMint(数量, proof)`，每人只能成功调用一次。

### 3. 保持「盲盒」状态

- 不调用 `setRevealed(true)`。
- 此时所有已铸造的 NFT 的 `tokenURI()` 都返回 `hiddenMetadataUri`（例如 `ipfs://__CID__/hidden.json`），即「让大家先看不到 NFT 长什么样」的同一张图/同一段元数据。

### 4. Reveal：展示真实 NFT

- 将真实元数据（图片、属性等）上传到 IPFS 或你的服务器，得到 base URI。
- 调用 `setUriPrefix(你的 base URI)`（如 `https://your-cdn.com/metadata/` 或 `ipfs://Qm.../`）。
- 确认合约里按 `uriPrefix + tokenId + uriSuffix` 能正确对应到每个 tokenId 的 JSON 文件（例如 `1.json`, `2.json`）。
- 调用 `setRevealed(true)`。
- 之后所有 token 的 `tokenURI()` 会返回各自真实元数据，即「将 hidden 设置为 false，让大家看到 NFT 长什么样」。

### 5. 公开发售

- 调用 `setPaused(false)`，开启公开 `mint()`。
- （可选）调用 `setCost`、`setMaxMintAmountPerTx` 设为公售价格和每笔上限（如配置里 0.09 ETH、每笔 5 个）。
- 任何人支付 `cost × 数量` 即可调用 `mint(数量)` 铸造。

### 6. 后续运营

- **setPaused(true)**：随时可再次暂停公售。
- **setCost / setMaxMintAmountPerTx**：调价或改每笔上限。
- **withdraw()**：将合约里的 ETH 提走（当前实现会先转 5% 给指定地址，剩余给 owner）。

---

## 流程小结

- **发消息 + 加白名单**：更新 `whitelist.json`（或等价名单）→ 生成 Merkle root → `setMerkleRoot` → `setWhitelistMintEnabled(true)`，白名单用户可 `whitelistMint` 提前铸造。
- **保持盲盒**：不调用 reveal，所有人看到的都是 `hiddenMetadataUri`。
- **Reveal**：上传真实元数据 → `setUriPrefix` → `setRevealed(true)`，大家才能看到每个 NFT 的真实样子。
- **公开发售**：`setPaused(false)`（并可选 `setCost` / `setMaxMintAmountPerTx`），开放 `mint()`。
- **之后**：可随时 `setPaused`、改 cost、`withdraw` 等。

---

## 如何学习手抄该项目

推荐按以下六个阶段从零手抄一遍，便于理解项目结构和合约/DAPP 逻辑。每步都有验收清单，可按顺序打勾完成。

| 阶段 | 说明 | 文档 |
|------|------|------|
| **阶段一** | 项目骨架与配置：monorepo、smart-contract 目录、Hardhat、CollectionConfig、占位合约，能 `yarn compile` | [step1.md](handcopy-steps/step1.md) |
| **阶段二** | ERC721 合约核心（不含白名单）：mint、tokenURI、reveal、onlyOwner 设置、部署脚本，能本地部署并 mint | [step2.md](handcopy-steps/step2.md) |
| **阶段三** | 白名单与 Reveal：whitelistMint、Merkle 校验、Hardhat 的 `generate-root-hash` / `generate-proof`，验证白名单 mint 与 reveal | [step3.md](handcopy-steps/step3.md) |
| **阶段四** | 销售阶段脚本与测试：2～8 脚本（白名单开/关、预售/公售开/关、reveal）、完整自动化测试 | [step4.md](handcopy-steps/step4.md) |
| **阶段五** | 铸造 DAPP 基础：前端工程、连接 MetaMask、读合约状态、CollectionStatus、MintWidget、Whitelist 工具 | [step5.md](handcopy-steps/step5.md) |
| **阶段六** | DAPP 铸造与白名单：mintTokens、whitelistMintTokens、Merkle proof 复制、错误与售罄处理 | [step6.md](handcopy-steps/step6.md) |

建议从 [step1.md](handcopy-steps/step1.md) 开始，每阶段验收通过后再进入下一阶段。

---

## 注意事项

当前合约**没有**单独的「preSale」阶段。若要做「白名单一个价、公售一个价」，只能在切换阶段时用 `setCost` 改价格，并配合 `setWhitelistMintEnabled(false)` 再 `setPaused(false)` 来区分阶段。
