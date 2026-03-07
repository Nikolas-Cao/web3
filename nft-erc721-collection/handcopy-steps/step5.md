# 阶段五：铸造 DAPP 基础

**目标**：搭好前端工程，实现「连接 MetaMask → 识别网络 → 读取合约状态 → 展示供应量/价格/暂停/白名单状态」；页面能正常跑起来并显示合约数据。

**前提**：阶段一～四已验收；`smart-contract` 已部署且 `CollectionConfig.contractAddress` 已填；在项目根目录下 `minting-dapp` 与 `smart-contract` 为同级目录。

---

## 一、目录与依赖

### 1.1 目录结构

在仓库根目录下确认存在 `minting-dapp/`，与 `smart-contract/` 同级。

### 1.2 前置：合约编译与类型

- 在 `smart-contract` 目录执行 `yarn compile`，确认生成 `artifacts/` 与 `typechain/`（若使用 typechain）。
- 若 `NftContractType` 从 typechain 引用，需保证 Hardhat 配置中已启用 `@typechain/hardhat` 且编译后存在 `smart-contract/typechain/index`。

### 1.3 package.json

**文件**：`minting-dapp/package.json`。

- devDependencies 需包含：react、react-dom、@types/react、@types/react-dom、ethers、@metamask/detect-provider、react-toastify、@symfony/webpack-encore、ts-loader、typescript、sass、sass-loader、tailwindcss、autoprefixer、postcss-loader、node-polyfill-webpack-plugin、keccak256、merkletreejs 等。
- scripts：`"dev": "encore dev"`、`"dev-server": "encore dev-server"`、`"watch": "encore dev --watch"`、`"build": "encore production --progress"`。

在 `minting-dapp` 下执行 `yarn`，确认依赖安装无报错。

---

## 二、构建与配置

### 2.1 TypeScript

**文件**：`minting-dapp/tsconfig.json`。

- compilerOptions：target、module 为 ESNext，jsx 为 react-jsx，strict: true，moduleResolution: "node"，esModuleInterop: true，resolveJsonModule: true。
- exclude 可包含 `../node_modules`。

### 2.2 Webpack（Encore）

**文件**：`minting-dapp/webpack.config.js`。

- 使用 @symfony/webpack-encore 与 node-polyfill-webpack-plugin。
- setOutputPath('public/build/')、setPublicPath('/build')。
- addEntry('main', './src/scripts/main.tsx')。
- copyFiles：from './src/images'，to '[path][name].[ext]'，context './src'。
- enableSassLoader、enableTypeScriptLoader、enablePostCssLoader、enableReactPreset。
- addPlugin(new NodePolyfillPlugin())。

### 2.3 PostCSS

**文件**：`minting-dapp/postcss.config.js`。plugins: { tailwindcss: {}, autoprefixer: {} }。

### 2.4 Tailwind

**文件**：`minting-dapp/tailwind.config.js`。mode: 'jit'；content 包含 './src/**/*.tsx'、'./public/index.html'；theme.extend.colors 按原项目配置（或最小集合）。

---

## 三、HTML 与静态资源

### 3.1 入口 HTML

**文件**：`minting-dapp/public/index.html`。

- 标准 HTML5；`<title>` 留空（由 main.tsx 用 CollectionConfig 设置）。
- 引入 `/build/main.css`、`/build/main.js`（与 Encore 输出一致）。
- 页面内包含：`<img id="logo" src="/build/images/logo.png" alt="Logo" />`、`<div id="minting-dapp"></div>`、`<div id="notifications"></div>`。

### 3.2 图片占位

- 在 `minting-dapp/src/images/` 下放置 logo.png、fav.png、preview.png（或占位图），避免 404。

---

## 四、样式

### 4.1 主样式入口

**文件**：`minting-dapp/src/styles/main.scss`。

- 引入 Tailwind 三行；再引入 `./components/general.scss`、`./components/minting-dapp.scss`。

### 4.2 general.scss

- body、a、strong、main、main .error、main button（含 .primary）、input[type=text]、label 等基础样式（可抄原项目 @apply）。

### 4.3 minting-dapp.scss

- 作用域 #minting-dapp；.no-wallet、.collection-not-ready、.collection-status、.not-mainnet、.collection-sold-out、.cannot-mint、.mint-widget 等，类名与 React 中 className 一致。

---

## 五、入口与配置引用

### 5.1 main.tsx

**文件**：`minting-dapp/src/scripts/main.tsx`。

- 引入 main.scss、react-toastify CSS、ReactDOM、Dapp、CollectionConfig（路径指向 smart-contract/config/CollectionConfig）、ToastContainer。
- 若 document.title === '' 则 document.title = CollectionConfig.tokenName。
- DOMContentLoaded 中：ToastContainer 渲染到 #notifications；Dapp 渲染到 #minting-dapp。

从 main.tsx 到 smart-contract 的路径按实际层级（如 `../../../smart-contract/config/CollectionConfig`）写对。

---

## 六、合约类型与 ABI

### 6.1 NftContractType

**文件**：`minting-dapp/src/scripts/lib/NftContractType.ts`。

- 从 smart-contract/typechain/index 导入合约类型并 re-export 为默认导出。路径如 `../../../../smart-contract/typechain/index`。

### 6.2 Dapp 中 ABI 的加载

- 在 Dapp.tsx 中通过 require 加载 ABI：路径指向 smart-contract/artifacts/contracts/<ContractName>.sol/<ContractName>.json 的 .abi，使用 CollectionConfig.contractName 拼路径。

---

## 七、Dapp 主组件（连接钱包与读合约）

**文件**：`minting-dapp/src/scripts/react/Dapp.tsx`。

### 7.1 依赖与类型

- State：userAddress、network、networkConfig、totalSupply、maxSupply、maxMintAmountPerTx、tokenPrice、isPaused、loading、isWhitelistMintEnabled、isUserInWhitelist、merkleProofManualAddress、merkleProofManualAddressFeedbackMessage、errorMessage。
- defaultState 中 networkConfig: CollectionConfig.mainnet，其余按「未连接、未加载」赋初值。

### 7.2 生命周期与 MetaMask

- componentDidMount：detectEthereumProvider()；若 !isMetaMask 则 setError（未检测到 MetaMask + 区块浏览器/Whitelist Proof 说明）；new Web3Provider(browserProvider)；registerWalletEvents；await initWallet()。

### 7.3 钱包事件

- accountsChanged → initWallet()；chainChanged → window.location.reload()。

### 7.4 连接与初始化

- connectWallet：eth_requestAccounts 后 initWallet()；catch 时 setError(e)。
- initWallet：listAccounts() 为空则 setState(defaultState) 并 return；getNetwork() 匹配 mainnet/testnet 得到 networkConfig，否则 setError('Unsupported network!')；setState userAddress、network、networkConfig；getCode(contractAddress) 若为 '0x' 则 setError 并 return；new ethers.Contract(contractAddress, ContractAbi, getSigner()) 赋给 this.contract；refreshContractState()。

### 7.5 合约状态刷新

- refreshContractState：读取 maxSupply、totalSupply、maxMintAmountPerTx、cost、paused、whitelistMintEnabled；isUserInWhitelist = Whitelist.contains(userAddress)；一次性 setState。BigNumber 用 .toNumber()（ethers v5）。

### 7.6 辅助方法

- isWalletConnected、isContractReady、isSoldOut、isNotMainnet；generateContractUrl、generateMarketplaceUrl、generateTransactionUrl；setError（支持 string/JSX/对象错误）。

### 7.7 渲染结构

- 非主网提示；errorMessage 与 Close；已连接且合约就绪时 CollectionStatus + MintWidget（或 sold out 区块）；未连接时 Connect Wallet、区块浏览器说明、Whitelist Proof 区块。mintTokens、whitelistMintTokens、copyMerkleProofToClipboard 在本阶段可一并实现（与阶段六一致）。

---

## 八、CollectionStatus 组件

**文件**：`minting-dapp/src/scripts/react/CollectionStatus.tsx`。

- Props：userAddress、totalSupply、maxSupply、isPaused、isWhitelistMintEnabled、isUserInWhitelist、isSoldOut。
- isSaleOpen() = (isWhitelistMintEnabled || !isPaused) && !isSoldOut。
- 渲染：钱包地址、Supply totalSupply/maxSupply、Sale status（Open / Whitelist only / Closed）。

---

## 九、MintWidget 组件

**文件**：`minting-dapp/src/scripts/react/MintWidget.tsx`。

- Props：networkConfig、maxSupply、totalSupply、tokenPrice、maxMintAmountPerTx、isPaused、loading、isWhitelistMintEnabled、isUserInWhitelist、mintTokens、whitelistMintTokens。
- State：mintAmount 默认 1。
- canMint()、canWhitelistMint()；increment/decrement 受 maxMintAmountPerTx 与 1 限制；mint() 根据 isPaused 调用 mintTokens 或 whitelistMintTokens。
- 渲染：可 mint 时预览图、总价、数量加减与 Mint 按钮；否则「未在白名单」或「合约暂停」提示。loading 时禁用按钮并加样式。

---

## 十、Whitelist 工具

**文件**：`minting-dapp/src/scripts/lib/Whitelist.ts`。

- 从 smart-contract/config/whitelist.json 引入地址数组。
- 建树：leafNodes = whitelistAddresses.map(addr => keccak256(addr))，new MerkleTree(leafNodes, keccak256, { sortPairs: true })。
- getProofForAddress(address)、getRawProofForAddress(address)、contains(address)；导出单例。

---

## 十一、验收

### 11.1 构建

```bash
cd minting-dapp
yarn build
```

- [ ] 无报错，生成 public/build/ 及 main.js、main.css、images。

### 11.2 本地运行

```bash
yarn dev
```

- [ ] 页面标题为 CollectionConfig.tokenName；未连接时显示 Connect Wallet 与区块浏览器、Whitelist Proof 说明。
- [ ] 连接 MetaMask 后，若链与合约正确，出现 Loading 再变为 CollectionStatus 与 MintWidget（或 sold out/cannot mint）。
- [ ] 不支持的链提示 Unsupported network!；无合约地址提示 Could not find the contract...。

### 11.3 状态与链接

- [ ] CollectionStatus 中 totalSupply/maxSupply、Sale status 与链上一致。
- [ ] 未连接时 Whitelist Proof 输入白名单地址可生成/复制或看到「not in the whitelist」。

---

## 十二、阶段五总验收清单

- [ ] minting-dapp 与 smart-contract 同级；smart-contract 已 compile。
- [ ] package.json、tsconfig、webpack、postcss、tailwind、index.html、src/images、样式与脚本已手抄。
- [ ] yarn build 通过；yarn dev 可打开页面；连接钱包后能正确显示合约状态与 Mint/白名单 UI。

---

## 十三、常见问题

- **找不到 smart-contract 模块**：确认目录结构；TS/Webpack 中路径层级正确。
- **typechain 不存在**：在 smart-contract 执行 yarn compile；或改用手写 ABI 类型。
- **getCode 返回 0x**：当前链与 contractAddress 所在链一致，且已部署。
- **Whitelist.contains 始终 false**：whitelist.json 与合约一致；地址格式、sortPairs: true。
- **样式或图片 404**：publicPath 为 /build；图片在 src/images 并被 copyFiles 复制。
