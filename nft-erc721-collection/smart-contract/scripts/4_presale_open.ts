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
        throw 'please close the whitelist sale before opening the presale';
    }

    const preSalePrice = utils.parseEther(CollectionConfig.preSale.price.toString());
    if (!await (await contract.cost()).eq(preSalePrice)) {
        console.log("update the token price to the presale price");
        await (await contract.setCost(preSalePrice)).wait();
    }

    if (!await (await contract.maxMintAmountPerTx()).eq(CollectionConfig.preSale.maxMintAmountPerTx)) {
        console.log("update the max mint amount per transaction to the presale max mint amount per transaction");

        await (await contract.setMaxMintAmountPerTx(CollectionConfig.preSale.maxMintAmountPerTx)).wait();
    }

    if (await contract.paused()) {
        console.log("unpause the contract");
        await (await contract.setPaused(false)).wait();
    } else {
        console.log("the contract is already unpaused!");
    }

    console.log("presale is now open!");
}

main().catch((error) =>{
    console.error(error);
    process.exitCode = 1;
});