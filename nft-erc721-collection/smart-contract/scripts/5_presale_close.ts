import {ethers} from 'hardhat';
import NftContractProvider from "../lib/NftContractProvider";

async function main() {
    const privateKey = process.env.DEPLOYER_PRIVATE_KEY;
    const signer = privateKey ? new ethers.Wallet(privateKey, ethers.provider) : (await ethers.getSigners())[0];
    if (privateKey) console.log('Using deployer address:', signer.address);

    const contract = await NftContractProvider.getContract(signer)

    if (!await contract.paused()) {
        console.log("pause the contract");
        await (await contract.setPaused(true)).wait();
    } else {
        console.log("the contract is already paused!");
    }

    console.log("presale is now closed!");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});