import { ethers } from 'hardhat';
import CollectionConfig from '../config/CollectionConfig';
import { NftContractType } from '../lib/NftContractProvider';
import ContractArguments from './../config/ContractArguments';

// Hardhat 默认第一个账户的私钥（npx hardhat node 预生成，约 10000 ETH）
// 仅用于本地/fork 时给 DEPLOYER 地址打款
const HARDHAT_DEFAULT_FIRST_ACCOUNT_PRIVATE_KEY =
  '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  console.log('Deploying contract...');

  // 若设置了 DEPLOYER_PRIVATE_KEY，则使用该私钥对应的钱包部署；否则使用默认第一个账户
  const privateKey = process.env.DEPLOYER_PRIVATE_KEY;
  const signer = privateKey
    ? new ethers.Wallet(privateKey, ethers.provider)
    : (await ethers.getSigners())[0];
  if (privateKey) {
    console.log('Deployer address:', signer.address);
    // 部署前：用 Hardhat 预生成账户给 DEPLOYER 转 100 ETH（仅本地/fork 有效）
    const faucet = new ethers.Wallet(HARDHAT_DEFAULT_FIRST_ACCOUNT_PRIVATE_KEY, ethers.provider);
    const deployerBalance = await signer.getBalance();
    const needEth = ethers.utils.parseEther('100');
    if (deployerBalance.lt(needEth)) {
      console.log('Funding deployer with 100 ETH from Hardhat default account...');
      const tx = await faucet.sendTransaction({
        to: signer.address,
        value: needEth,
      });
      await tx.wait();
      console.log('Funded. Tx:', tx.hash);
    }
  }

  // We get the contract to deploy
  const Contract = await ethers.getContractFactory(CollectionConfig.contractName, signer);
  const contract = await Contract.deploy(...ContractArguments) as NftContractType;

  await contract.deployed();

  console.log('Contract deployed to:', contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
