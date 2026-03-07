# 阶段四：销售阶段脚本与测试

**目标**：用 CLI 脚本完整跑通「白名单开 → 关 → 预售开 → 关 → 公售开 → 关 → Reveal」，并有一份完整自动化测试覆盖部署、白名单、公售、权限、tokenURI 等。

**前提**：阶段一～三已验收（合约可编译部署、`CollectionConfig.contractAddress` 已填、`NftContractProvider` 可用）。

---

## 一、依赖与前置

### 1.1 NftContractProvider

- 确认 `smart-contract/lib/NftContractProvider.ts` 已存在且逻辑正确：根据 `CollectionConfig.contractAddress` 和 `contractName` 用 `ethers.getContractAt` 获取合约实例并返回；若未配置地址或链上无合约则 throw。
- 确认 typechain 已配置并在 `NftContractProvider` 中引用生成的合约类型（与 `YourNftToken` 一致）。

### 1.2 package.json 脚本

在 `smart-contract/package.json` 的 `scripts` 中增加：

- `"whitelist-open": "hardhat run scripts/2_whitelist_open.ts"`
- `"whitelist-close": "hardhat run scripts/3_whitelist_close.ts"`
- `"presale-open": "hardhat run scripts/4_presale_open.ts"`
- `"presale-close": "hardhat run scripts/5_presale_close.ts"`
- `"public-sale-open": "hardhat run scripts/6_public_sale_open.ts"`
- `"public-sale-close": "hardhat run scripts/7_public_sale_close.ts"`
- `"reveal": "hardhat run scripts/8_reveal.ts"`

运行时会使用 hardhat 默认网络；对指定网络执行时在命令后加 `--network <网络名>`。

---

## 二、脚本 2_whitelist_open.ts

**作用**：开启白名单销售（设置价格、单次上限、Merkle root、并开启 whitelist mint）。

**实现要点**：

1. **Import**：`utils` from `ethers`；`MerkleTree` from `merkletreejs`；`keccak256`；`CollectionConfig`；`NftContractProvider`。
2. **main 开头**：若 `CollectionConfig.whitelistAddresses.length < 1`，则 throw 错误提示白名单为空。
3. **建 Merkle 树**：与阶段三的 `generate-root-hash` 一致——`leafNodes = CollectionConfig.whitelistAddresses.map(addr => keccak256(addr))`，`new MerkleTree(leafNodes, keccak256, { sortPairs: true })`，`rootHash = '0x' + merkleTree.getRoot().toString('hex')`。
4. **连接合约**：`const contract = await NftContractProvider.getContract();`
5. **价格**：`whitelistPrice = utils.parseEther(CollectionConfig.whitelistSale.price.toString())`；若当前 `await contract.cost()` 与之不等，则 `contract.setCost(whitelistPrice)` 并 `.wait()`。
6. **单次上限**：若当前 `contract.maxMintAmountPerTx()` 与 `CollectionConfig.whitelistSale.maxMintAmountPerTx` 不等，则 `contract.setMaxMintAmountPerTx(...)` 并 `.wait()`。
7. **Merkle root**：若 `await contract.merkleRoot()` !== rootHash，则 `contract.setMerkleRoot(rootHash)` 并 `.wait()`。
8. **开启白名单**：若 `!await contract.whitelistMintEnabled()`，则 `contract.setWhitelistMintEnabled(true)` 并 `.wait()`。
9. **结尾**：`console.log('Whitelist sale has been enabled!');`
10. **错误处理**：`main().catch((error) => { console.error(error); process.exitCode = 1; });`

比较 cost 时用 `(await contract.cost()).eq(whitelistPrice)`，避免用 `===` 比较 BigNumber。

---

## 三、脚本 3_whitelist_close.ts

**作用**：关闭白名单销售。Import `NftContractProvider`；获取合约后若 `await contract.whitelistMintEnabled()` 为 true，则 `contract.setWhitelistMintEnabled(false)` 并 `.wait()`；`console.log('Whitelist sale has been disabled!');` 及统一 catch。

---

## 四、脚本 4_presale_open.ts

**作用**：开启预售（价格与单次上限改为 preSale，并 unpause）。Import `utils`、`CollectionConfig`、`NftContractProvider`。获取合约后若 `whitelistMintEnabled` 为 true 则 throw 提示先关闭白名单。将 cost 设为 preSale.price、maxMintAmountPerTx 设为 preSale.maxMintAmountPerTx（若与当前不等则更新）；若 paused 则 setPaused(false)。`console.log('Pre-sale is now open!');`

---

## 五、脚本 5_presale_close.ts

**作用**：关闭预售（pause）。若 `!await contract.paused()` 则 `contract.setPaused(true)` 并 wait。`console.log('Pre-sale is now closed!');`

---

## 六、脚本 6_public_sale_open.ts

**作用**：开启公售。与 4 类似，使用 `CollectionConfig.publicSale`；同样先检查 whitelistMintEnabled，若为 true 则 throw。`console.log('Public sale is now open!');`

---

## 七、脚本 7_public_sale_close.ts

**作用**：关闭公售（pause）。与 5 相同，log 改为 `'Public sale is now closed!'`。

---

## 八、脚本 8_reveal.ts

**作用**：设置元数据 URI 前缀并执行 reveal。

1. **环境变量**：脚本开头检查 `process.env.COLLECTION_URI_PREFIX` 存在且不等于占位值（如 `'ipfs://__CID___/'`），否则 throw，提示先在 ENV 中配置 URI 前缀。
2. 在 `.env` 中增加：`COLLECTION_URI_PREFIX=ipfs://你的CID/`（或实际 base URI）。
3. 获取合约后，若 `await contract.uriPrefix()` !== `process.env.COLLECTION_URI_PREFIX`，则 `contract.setUriPrefix(process.env.COLLECTION_URI_PREFIX)` 并 wait。
4. 若 `!await contract.revealed()`，则 `contract.setRevealed(true)` 并 wait。
5. `console.log('Your collection is now revealed!');` 与统一 catch。

---

## 九、测试文件 test/index.ts

**作用**：覆盖部署、初始状态、暂停时禁止 mint、白名单 mint、预售/公售 mint、仅 owner 可调函数、tokensOfOwner、可选的大供应量测试、reveal 后 tokenURI。

### 9.1 依赖与工具

- Import：chai、expect、ChaiAsPromised、BigNumber/utils from ethers、ethers from hardhat、MerkleTree、keccak256、CollectionConfig、ContractArguments、NftContractType、SignerWithAddress。
- `chai.use(ChaiAsPromised);`
- 定义 `SaleType` 枚举（whitelistSale.price、preSale.price、publicSale.price）。
- 定义 `getPrice(saleType, mintAmount)`：`utils.parseEther(saleType.toString()).mul(mintAmount)`。
- 定义测试用 `whitelistAddresses`（Hardhat 默认账户地址，与 getSigners 中部分一致）。

### 9.2 describe 与 before

- `describe(CollectionConfig.contractName, ...)`；声明 owner、whitelistedUser、holder、externalUser、contract。
- `before`：`[owner, whitelistedUser, holder, externalUser] = await ethers.getSigners();`

### 9.3 用例概要

- **Contract deployment**：用 ContractArguments 部署，赋给 contract。
- **Check initial data**：断言 name、symbol、cost、maxSupply、maxMintAmountPerTx、hiddenMetadataUri、paused、whitelistMintEnabled、revealed；tokenURI(1) 应 revert（未 mint）。
- **Before any sale**：各类用户 mint/whitelistMint 均应 revert；owner 的 mintForAddress 成功；超额 mintForAddress revert；断言各 balance。
- **Whitelist sale**：建 Merkle 树并 setMerkleRoot、setWhitelistMintEnabled；whitelistedUser 用正确 proof 成功 whitelistMint；重复 claim、超额、金额不足、他人 proof、错误 proof、空 proof 均 revert；关闭白名单并改 cost。
- **Pre-sale**：setMaxMintAmountPerTx、setPaused(false)；holder/whitelistedUser mint；金额不足、超额、whitelistMint 失败；setPaused(true)、cost 改为 publicSale。
- **Owner only functions**：externalUser 调用 mintForAddress、setRevealed、setCost、setMaxMintAmountPerTx、setHiddenMetadataUri、setUriPrefix、setUriSuffix、setPaused、setMerkleRoot、setWhitelistMintEnabled、withdraw 均 revert（Ownable）。
- **Wallet of owner**：断言 tokensOfOwner 与预期 tokenId 列表一致。
- **Supply checks (long)**（可选）：若 `process.env.EXTENDED_TESTS` 未设置则 skip；大量 mint 至接近 maxSupply、超额 revert、最后 mint 至售罄。
- **Token URI generation**：未 reveal 时 tokenURI(1) 为 hiddenMetadataUri；setUriPrefix、setRevealed(true)；tokenURI(0) revert；tokenURI(1) 与 tokenURI(totalSupply) 为 base+id+.json。

测试中 `whitelistAddresses` 必须包含 whitelistedUser 的地址、不包含 holder/externalUser，以便「用 holder 带 whitelistedUser 的 proof」得到 Invalid proof。

---

## 十、验收

### 10.1 脚本可执行性

在 `smart-contract` 目录下，对已部署合约执行：

```bash
yarn whitelist-open
yarn whitelist-close
yarn presale-open
yarn presale-close
yarn public-sale-open
yarn public-sale-close
```

- [ ] 每条命令均执行成功（白名单为空时 2 会报错属预期）。
- [ ] 在 `.env` 中设置 `COLLECTION_URI_PREFIX` 后执行 `yarn reveal`，应成功。

### 10.2 测试

```bash
yarn test
```

- [ ] 所有非 skip 的用例通过。
- [ ] 可选：`EXTENDED_TESTS=1 yarn test` 通过「Supply checks (long)」。

---

## 十一、阶段四总验收清单

- [ ] NftContractProvider 可用，package.json 中 7 个脚本已添加。
- [ ] 2～8 脚本已按要点手抄并能在对应网络运行。
- [ ] .env 中已配置 COLLECTION_URI_PREFIX（用于 8_reveal）。
- [ ] test/index.ts 已手抄，`yarn test` 全过；可选 EXTENDED_TESTS=1 通过。

---

## 十二、常见问题

- **“Please add the contract address”**：CollectionConfig.contractAddress 为 null，先部署并写入地址。
- **“Can't find a contract deployed”**：当前 Hardhat 连接的网络上该地址无合约，检查网络与地址。
- **8_reveal 报错 URI prefix**：在 .env 中设置 COLLECTION_URI_PREFIX，且不要用占位值。
- **测试 Invalid proof / Address already claimed**：确认 whitelistAddresses 与建树方式、合约一致，且 whitelistedUser 在列表中。
- **BigNumber 比较**：用 `.eq(price)`，不要用 `===`。
