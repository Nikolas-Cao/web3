# 阶段二：ERC721 合约核心（不含白名单）

**目标**：实现可部署、可公售 mint 的合约，并跑通部署脚本。

**前提**：阶段一已验收。

---

## 一、合约依赖

- 确认 `smart-contract/package.json` 已含 `@openzeppelin/contracts`、`erc721a`（若用 ERC721A）。

---

## 二、合约本体（核心逻辑，无白名单可先占位）

在 `smart-contract/contracts/YourNftToken.sol` 中按顺序实现：

1. **pragma 与 import**：`pragma solidity >=0.8.9 <0.9.0;`，import ERC721AQueryable、Ownable、ReentrancyGuard、MerkleProof（可先保留为后续白名单用）。
2. **状态变量**：merkleRoot、whitelistClaimed、uriPrefix、uriSuffix、hiddenMetadataUri、cost、maxSupply、maxMintAmountPerTx、paused、whitelistMintEnabled、revealed。
3. **constructor**：按 ContractArguments 赋值（setCost、maxSupply、setMaxMintAmountPerTx、setHiddenMetadataUri）。
4. **modifier**：mintCompliance（数量 &gt; 0、≤ maxMintAmountPerTx，totalSupply + _mintAmount ≤ maxSupply）、mintPriceCompliance（msg.value >= cost * _mintAmount）。
5. **mint(uint256 _mintAmount)**：payable，修饰符 mintCompliance、mintPriceCompliance，require(!paused)，_safeMint(_msgSender(), _mintAmount)。
6. **_startTokenId()**：override 返回 1。
7. **tokenURI(uint256 _tokenId)**：require(_exists(_tokenId))；若 revealed == false 返回 hiddenMetadataUri，否则返回 baseURI + tokenId + uriSuffix。
8. **onlyOwner 设置函数**：setCost、setMaxMintAmountPerTx、setHiddenMetadataUri、setUriPrefix、setUriSuffix、setPaused。白名单相关（whitelistMint、setMerkleRoot、setWhitelistMintEnabled）可留空或注释，阶段三再补。
9. **mintForAddress(uint256 _mintAmount, address _receiver)**：onlyOwner，mintCompliance，_safeMint(_receiver, _mintAmount)。
10. **withdraw()**（可选）：onlyOwner、nonReentrant，按需转出并转给 owner。
11. **_baseURI()**：override 返回 uriPrefix。

---

## 三、部署脚本

- **smart-contract/scripts/1_deploy.ts**：从原项目复制——ethers.getContractFactory(CollectionConfig.contractName)、deploy(...ContractArguments)、await contract.deployed()、console.log 地址。

在本地链测试：

```bash
cd smart-contract
yarn hardhat node
# 新开终端
yarn deploy --network localhost
```

验收：终端打印合约地址，无 revert。

---

## 四、写入部署地址

- 在 `smart-contract/config/CollectionConfig.ts` 中将 `contractAddress: null` 改为上一步打印的地址（字符串）。

---

## 五、可选：NftContractProvider

- **smart-contract/lib/NftContractProvider.ts**：从原项目复制；依赖 typechain 生成的类型，若尚未配置 typechain 可先注释或跳过，阶段四再补。

---

## 六、阶段二总验收清单

- [ ] `yarn compile` 通过
- [ ] `yarn deploy --network localhost` 成功并拿到合约地址
- [ ] 在 Hardhat console 或一次性脚本中调用 `mint(1)` 并付 cost 的 ether，能成功铸造
- [ ] `CollectionConfig.contractAddress` 已填为部署地址
