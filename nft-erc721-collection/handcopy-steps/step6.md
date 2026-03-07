# 阶段六：DAPP 铸造与白名单

**目标**：在页面上能完成公售 mint 与白名单 mint，支持「手动输入地址生成并复制 Merkle proof」在区块浏览器使用；铸造流程、Loading、错误与 Toast 行为正确。

**前提**：阶段五已验收（DAPP 能跑、能连钱包、能读合约状态并展示 CollectionStatus / MintWidget）。

---

## 一、Dapp 铸造逻辑核对

### 1.1 mintTokens

**文件**：`minting-dapp/src/scripts/react/Dapp.tsx`。

确认实现：

- 入参：`amount: number`。
- 开头：`this.setState({ loading: true })`。
- 调用合约：`this.contract.mint(amount, { value: this.state.tokenPrice.mul(amount) })`，得到 `transaction`。
- Toast：`toast.info` 提示「Transaction sent! Please wait...」并带 `generateTransactionUrl(transaction.hash)` 的链接。
- 等待：`const receipt = await transaction.wait()`。
- 成功：`toast.success` 带 `generateTransactionUrl(receipt.transactionHash)` 的链接。
- 收尾：`this.refreshContractState()`、`this.setState({ loading: false })`。
- catch：`this.setError(e)`、`this.setState({ loading: false })`。

金额必须为 `tokenPrice.mul(amount)`，与合约 `mintPriceCompliance` 一致。

### 1.2 whitelistMintTokens

确认实现：

- 入参：`amount: number`。
- 开头：`this.setState({ loading: true })`。
- Proof：`Whitelist.getProofForAddress(this.state.userAddress!)`，传给合约。
- 调用：`this.contract.whitelistMint(amount, proof, { value: this.state.tokenPrice.mul(amount) })`。
- Toast、wait、success、refreshContractState、loading false、catch 与 mintTokens 相同。

仅当当前连接的钱包地址在白名单内时，getProofForAddress 才有效。

---

## 二、Merkle Proof 复制流程

### 2.1 copyMerkleProofToClipboard

- 取地址：`this.state.userAddress ?? this.state.merkleProofManualAddress`。
- 调用：`Whitelist.getRawProofForAddress(address)`。
- 若返回长度 < 1：setState 提示「The given address is not in the whitelist, please double-check.」，return。
- 否则：`navigator.clipboard.writeText(merkleProof)`，再 setState 成功文案（恭喜、已复制、可粘贴到区块浏览器）。链接用 `generateContractUrl()`。

### 2.2 手动输入与展示

- 未连接或白名单开启时展示「Whitelist Proof」区块。
- 输入框 value/onChange 更新 merkleProofManualAddress；已连接时可 disabled。
- 按钮点击触发 copyMerkleProofToClipboard()。
- 反馈：merkleProofManualAddressFeedbackMessage 展示错误或成功提示。

### 2.3 兼容性

- `replaceAll` 若不支持可改为 `replace(/'/g, '').replace(/ /g, '')`。
- 剪贴板：生产环境可考虑 navigator.clipboard 不可用时的降级。

---

## 三、MintWidget 行为核对

**文件**：`minting-dapp/src/scripts/react/MintWidget.tsx`。

### 3.1 是否可 mint

- canMint()：`!this.props.isPaused || this.canWhitelistMint()`。
- canWhitelistMint()：`this.props.isWhitelistMintEnabled && this.props.isUserInWhitelist`。

### 3.2 数量与金额

- incrementMintAmount：不超过 maxMintAmountPerTx。
- decrementMintAmount：不小于 1。
- 总价：`utils.formatEther(this.props.tokenPrice.mul(this.state.mintAmount))` + symbol。

### 3.3 点击 Mint

- mint()：若 !isPaused 调用 mintTokens，否则调用 whitelistMintTokens。
- 按钮与加减在 loading 时 disabled；容器在 loading 时加 animate-pulse saturate-0 pointer-events-none。

### 3.4 不可 mint 时的提示

- !canMint() 时显示「cannot-mint」：白名单阶段「You are not included in the whitelist」；仅暂停「The contract is paused」；并提示下次开售再来。

---

## 四、Whitelist 与合约一致性

**文件**：`minting-dapp/src/scripts/lib/Whitelist.ts`。

### 4.1 数据源

- 引入的 whitelist.json 与合约端脚本（如 2_whitelist_open）使用的列表一致。

### 4.2 建树参数

- leafNodes = whitelistAddresses.map(addr => keccak256(addr))。
- new MerkleTree(leafNodes, keccak256, { sortPairs: true })。
- 与合约 leaf、Hardhat task 一致；地址格式与链上一致。

### 4.3 方法

- getProofForAddress(address)：返回 getHexProof(keccak256(address))，供 whitelistMint 使用。
- getRawProofForAddress(address)：供复制到剪贴板。
- contains(address)：供 isUserInWhitelist 与 UI 判断。

---

## 五、错误与边界

### 5.1 用户拒绝 / 链上失败

- 进入 catch，setError(e)，loading 置回 false，按钮恢复。
- setError 能处理对象错误（error?.error?.message、error?.data?.message、error?.message）。

### 5.2 售罄

- isSoldOut() 为 true 时不渲染 MintWidget，改为「Tokens have been sold out!」及市场链接。

### 5.3 非主网

- 已连接但 chainId 非 mainnet/testnet 时提示「Unsupported network!」；testnet 时顶部显示非主网提示。

---

## 六、验收

### 6.1 公售 Mint（测试网或本地）

- 合约处于公售，钱包有足够余额。
- [ ] 出现「Transaction sent! Please wait...」及区块浏览器链接。
- [ ] 交易确认后 Success toast，Supply 增加。
- [ ] 拒绝或失败时错误提示出现且可关闭，按钮恢复。

### 6.2 白名单 Mint

- 合约开启白名单，当前地址在 whitelist.json 中且未 claim 过。
- [ ] 页面显示可 mint；点击 Mint 后走 whitelistMintTokens，交易成功，Supply 增加。
- [ ] 同一地址再次白名单 mint 被合约拒绝，错误信息正确展示。

### 6.3 Merkle Proof 复制

- 未连接：输入白名单地址，点击「Generate and copy to clipboard」。
- [ ] 成功提示，剪贴板为可粘贴的 proof 字符串。
- [ ] 输入非白名单地址时提示「not in the whitelist」。
- 已连接且在白名单：点击生成并复制，可在区块浏览器 whitelistMint 中粘贴使用。

### 6.4 不可 mint 时的 UI

- 合约暂停且不在白名单：显示「The contract is paused」或「You are not included in the whitelist」及「Please come back during the next sale!」。
- 售罄：显示 sold out 与市场链接，无 MintWidget。

---

## 七、阶段六总验收清单

- [ ] mintTokens、whitelistMintTokens 完整实现（含 loading、toast、refresh、catch）。
- [ ] MintWidget 根据 pause/whitelist 正确调用 mintTokens 或 whitelistMintTokens，loading 时禁用并防重复。
- [ ] copyMerkleProofToClipboard 与「Whitelist Proof」输入/按钮/反馈已实现且与 Whitelist 一致。
- [ ] Whitelist 与合约使用相同 whitelist 与建树方式；getProofForAddress/getRawProofForAddress/contains 正确。
- [ ] 在测试网或本地完成至少一次公售 mint 与一次白名单 mint；无 MetaMask 时可通过复制 proof 在区块浏览器成功 whitelistMint。
- [ ] 错误、售罄、非主网提示与 UI 状态符合预期。

---

## 八、常见问题

- **「Invalid proof」**：DAPP 的 whitelist.json 与合约 setMerkleRoot 使用的列表一致；建树用 keccak256(addr)、sortPairs: true；地址大小写与链上一致。
- **「Address already claimed」**：该地址已执行过 whitelistMint；可换地址或走公售。
- **复制无反应或报错**：检查 HTTPS 或 localhost；getRawProofForAddress 返回非空字符串。
- **Toast 不出现**：确认 ToastContainer 挂到 #notifications，并引入 react-toastify CSS。
- **金额不足 / 超额**：前端 tokenPrice.mul(amount) 与合约 cost() 一致；数量由 MintWidget 的 increment 上限保证不超过 maxMintAmountPerTx。

按上述逐项核对并打勾后，阶段六即完成；整个「合约 + 脚本 + 测试 + DAPP 铸造与白名单」手抄流程即可收尾。
