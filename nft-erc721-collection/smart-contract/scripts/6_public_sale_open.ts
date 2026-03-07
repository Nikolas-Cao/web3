import {utils} from 'ethers';
import {ethers} from 'hardhat';
import CollectionConfig from '../config/CollectionConfig';
import nftContractProvider from '../lib/NftContractProvider';

async function main() {
    const privateKey = process.env.DEPLOYER_PRIVATE_KEY;
    const signer = privateKey ? new ethers.Wallet(privateKey, ethers.provider) : (await ethers.getSigners())[0];
    if (privateKey) console.log('Using deployer address:', signer.address);

    const contract = await nftContractProvider.getContract(signer);

    if (await contract.whitelistMintEnabled()) {
        throw 'please close the whitelist sale before opening the public sale';
    }

    const publicSalePrice = utils.parseEther(CollectionConfig.publicSale.price.toString());
    if (!await (await contract.cost()).eq(publicSalePrice)) {
        console.log("update the token price to the public sale price");

        await (await contract.setCost(publicSalePrice)).wait();
    }

    if (!await (await contract.maxMintAmountPerTx()).eq(CollectionConfig.publicSale.maxMintAmountPerTx)) {
        console.log("update the max mint amount per transaction to the public sale max mint amount per transaction");
        await (await contract.setMaxMintAmountPerTx(CollectionConfig.publicSale.maxMintAmountPerTx)).wait();
    }

    if (await contract.paused()) {
        console.log("unpause the contract");

        await (await contract.setPaused(false)).wait();
    } else {
        console.log("the contract is already unpaused!");
    }

    console.log("public sale is now open!");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});