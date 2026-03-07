import {ethers} from 'hardhat';
import NftContractProvider from "../lib/NftContractProvider";

async function main() {
    const privateKey = process.env.DEPLOYER_PRIVATE_KEY;
    const signer = privateKey ? new ethers.Wallet(privateKey, ethers.provider) : (await ethers.getSigners())[0];
    if (privateKey) console.log('Using deployer address:', signer.address);

    const contract = await NftContractProvider.getContract(signer);

    if (await contract.whitelistMintEnabled()) {
        console.log("disable the whitelist mint");
        await (await contract.setWhitelistMintEnabled(false)).wait();
    } else {
        console.log("whitelist sale is already closed!");
    }

    console.log("whitelist sale is now closed!");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});