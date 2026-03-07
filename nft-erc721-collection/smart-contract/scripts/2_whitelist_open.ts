import {utils} from 'ethers';
import {ethers} from 'hardhat';
import {MerkleTree} from 'merkletreejs';
import keccak256 from 'keccak256';
import CollectionConfig from '../config/CollectionConfig';
import NftContractProvider from '../lib/NftContractProvider';

async function main() {
    const privateKey = process.env.DEPLOYER_PRIVATE_KEY;
    const signer = privateKey ? new ethers.Wallet(privateKey, ethers.provider) : (await ethers.getSigners())[0];
    if (privateKey) console.log('Using deployer address:', signer.address);

    if (CollectionConfig.whitelistAddresses.length < 1) {
        throw 'The whitelist is empty, please add some addresses to the configuration.';
    }

    const leafNodes = CollectionConfig.whitelistAddresses.map(addr => keccak256(addr));
    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true});
    const rootHash = '0x' + merkleTree.getRoot().toString('hex');

    const contract = await NftContractProvider.getContract(signer);

    const whitelistPrice = utils.parseEther(CollectionConfig.whitelistSale.price.toString())
    if (!await (await contract.cost()).eq(whitelistPrice)) {
        console.log("update the token price to the whitelist price");
        await (await contract.setCost(whitelistPrice)).wait();
    }

    if (!await (await contract.maxMintAmountPerTx()).eq(CollectionConfig.whitelistSale.maxMintAmountPerTx)) {
        console.log("update the max mint amount per transaction to the whitelist max mint amount per transaction");
        await (await contract.setMaxMintAmountPerTx(CollectionConfig.whitelistSale.maxMintAmountPerTx)).wait();
    }

    if ((await contract.merkleRoot()) !== rootHash) {
        console.log("update the merkle root to the new root hash");
        await (await contract.setMerkleRoot(rootHash)).wait();
    }

    if (!await contract.whitelistMintEnabled()) {
        console.log("enable the whitelist mint");
        await (await contract.setWhitelistMintEnabled(true)).wait();
    }

    console.log("whitelist sale is now open!");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});