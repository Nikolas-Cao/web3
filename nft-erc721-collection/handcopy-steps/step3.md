# 阶段三：白名单与 Reveal

**目标**：在合约中完整实现白名单（Merkle 校验）与 Reveal（隐藏/展示元数据），并在 Hardhat 中加入生成 Merkle 根与 proof 的 task，能验证白名单 mint 与 reveal 后 tokenURI 的变化。

**前提**：阶段二已完成（合约可编译、可部署，具备基础 `mint`）。

---

## 一、合约：白名单相关

### 1.1 依赖与状态变量

- 在 `YourNftToken.sol` 顶部确认已有：`import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';`
- 在状态变量区域确认或添加：`bytes32 public merkleRoot;`、`mapping(address => bool) public whitelistClaimed;`、`bool public whitelistMintEnabled = false;`

### 1.2 函数 whitelistMint

新增函数，建议按以下顺序实现：

1. 函数签名：`function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable`
2. 修饰符：`mintCompliance(_mintAmount)`、`mintPriceCompliance(_mintAmount)`
3. 函数体内依次：`require(whitelistMintEnabled, '...');`、`require(!whitelistClaimed[_msgSender()], '...');`、`bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));`、`require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), '...');`、`whitelistClaimed[_msgSender()] = true;`、`_safeMint(_msgSender(), _mintAmount);`

> **注意**：leaf 必须与脚本/前端一致，为「发送者地址」的 `keccak256(abi.encodePacked(_msgSender()))`，不要加其他参数。

### 1.3 函数 setMerkleRoot 与 setWhitelistMintEnabled

- **setMerkleRoot(bytes32 _merkleRoot)**：仅 `onlyOwner`，内部 `merkleRoot = _merkleRoot;`
- **setWhitelistMintEnabled(bool _state)**：仅 `onlyOwner`，内部 `whitelistMintEnabled = _state;`

---

## 二、合约：Reveal 与元数据 URI

### 2.1 状态变量

确认或添加：`string public uriPrefix = '';`、`string public uriSuffix = '.json';`、`string public hiddenMetadataUri;`、`bool public revealed = false;`

### 2.2 函数 tokenURI

实现逻辑（与当前项目一致）：

1. `require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');`
2. 若 `revealed == false`，直接 `return hiddenMetadataUri;`
3. 否则取 `currentBaseURI = _baseURI();`，若 `bytes(currentBaseURI).length > 0` 则返回 `string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))`，否则返回 `''`。

### 2.3 函数 _baseURI

```solidity
function _baseURI() internal view virtual override returns (string memory) {
  return uriPrefix;
}
```

### 2.4 onlyOwner 设置函数

确认或添加：**setRevealed(bool _state)**、**setHiddenMetadataUri**、**setUriPrefix**、**setUriSuffix**（均为 onlyOwner，仅做赋值）。

---

## 三、合约：withdraw（可选）

- 若需与项目一致：实现 **withdraw()**，使用 `onlyOwner` 与 `nonReentrant`，先按项目比例转出（不需要可改为 0% 或删除），再将余额转给 `owner()`。
- 合约需继承 `ReentrancyGuard`，并在 `withdraw` 上使用 `nonReentrant`。若阶段二已实现，本步仅作核对。

---

## 四、Hardhat 配置与依赖

### 4.1 依赖

在 `smart-contract/package.json` 中确认已安装：`merkletreejs`、`keccak256`。

### 4.2 hardhat.config.ts 顶部

在 `smart-contract/hardhat.config.ts` 中增加：`import { MerkleTree } from 'merkletreejs';`、`import keccak256 from 'keccak256';`、`import CollectionConfig from './config/CollectionConfig';`

---

## 五、Hardhat 自定义 Task

### 5.1 generate-root-hash

- **名称**：`generate-root-hash`
- **描述**：例如 "Generates and prints out the root hash for the current whitelist"
- **逻辑**：若 `CollectionConfig.whitelistAddresses.length < 1` 则 throw；`leafNodes = CollectionConfig.whitelistAddresses.map(addr => keccak256(addr))`；`merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })`；`rootHash = '0x' + merkleTree.getRoot().toString('hex')`；`console.log('The Merkle Tree root hash for the current whitelist is: ' + rootHash);`

### 5.2 generate-proof

- **名称**：`generate-proof`
- **描述**：例如 "Generates and prints out the whitelist proof for the given address"
- **逻辑**：同样先检查 whitelist 非空、用相同方式建 MerkleTree；使用位置参数 `taskArgs.address`，并通过 `.addPositionalParam('address', 'The public address')` 声明；`proof = merkleTree.getHexProof(keccak256(taskArgs.address)).toString().replace(/'/g, '').replace(/ /g, '')`；`console.log('The whitelist proof for the given address is: ' + proof);`

> **注意**：建树必须使用 `sortPairs: true`，与合约验证一致；地址格式（如 0x 小写）要与链上 sender 一致。

**用本机 MetaMask 做白名单验证**：在阶段一已配置 `.env` 中的 `DEPLOYER_PRIVATE_KEY` 的前提下，把该私钥对应的地址（即你用来部署/操作的 MetaMask 地址）加入 `config/whitelist.json`（例如放在数组最后）。部署并执行 `yarn whitelist-open` 后，即可用该 MetaMask 账号在前端或区块浏览器调用 `whitelistMint` 完成自测，无需额外测试地址。

### 5.3 package.json 脚本

在 `smart-contract/package.json` 的 `scripts` 中增加：`"root-hash": "hardhat generate-root-hash"`、`"proof": "hardhat generate-proof"`

---

## 六、验收

### 6.1 编译与 Merkle 命令

在 `smart-contract` 目录执行：

```bash
yarn compile
yarn root-hash
```

- [ ] `yarn compile` 通过
- [ ] 控制台输出形如：`The Merkle Tree root hash for the current whitelist is: 0x...`
- 若报错「whitelist is empty」，检查 `config/whitelist.json` 与 `CollectionConfig.ts` 中的 `whitelistAddresses` 已正确引入且非空

再执行（将 `YOUR_ADDRESS` 换成 `whitelist.json` 中存在的地址）：

```bash
yarn proof YOUR_ADDRESS
```

- [ ] 控制台输出形如：`The whitelist proof for the given address is: [...]`

### 6.2 白名单 mint 与 Reveal 行为

任选一种方式验证：

**方式 A：跑现有测试** — 在 `smart-contract` 下执行 `yarn test`；测试中应包含白名单 mint 与 reveal 后 tokenURI 变化。

**方式 B：手写临时脚本** — 部署后设置 merkleRoot、setWhitelistMintEnabled(true)，用正确 proof 调用 whitelistMint；再 setRevealed(true)、setUriPrefix，检查 tokenURI(1) 从未 reveal 的 hidden 变为 base+id+suffix。

---

## 七、阶段三总验收清单

- [ ] 合约包含：merkleRoot、whitelistClaimed、whitelistMint、setMerkleRoot、setWhitelistMintEnabled
- [ ] 合约包含：revealed、hiddenMetadataUri、uriPrefix/uriSuffix、tokenURI（未 reveal 返回 hidden）、_baseURI、setRevealed、setUriPrefix/setUriSuffix/setHiddenMetadataUri
- [ ] `yarn compile` 通过
- [ ] `yarn root-hash` 能输出 Merkle root
- [ ] `yarn proof <whitelist 中的地址>` 能输出 proof
- [ ] 白名单用户能用正确 proof 成功 whitelistMint；reveal 前后 tokenURI 行为符合预期

---

## 八、常见问题

- **"Invalid proof"**：检查 (1) 合约里 leaf 是否为 `keccak256(abi.encodePacked(msg.sender))`；(2) 脚本/前端建树是否用 `keccak256(addr)` 且地址与链上 sender 一致（含大小写、0x）；(3) 是否使用 `sortPairs: true`。
- **"Address already claimed"**：该地址已执行过 whitelistMint，每个地址只能白名单 mint 一次。
- **setMerkleRoot 的值**：部署后需用 `yarn root-hash` 得到的 root 调用 `setMerkleRoot`，否则 proof 对不上。
