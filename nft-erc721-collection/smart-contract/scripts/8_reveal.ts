import {ethers} from 'hardhat';
import NftContractProvider from "../lib/NftContractProvider";

async function main() {
    const privateKey = process.env.DEPLOYER_PRIVATE_KEY;
    const signer = privateKey ? new ethers.Wallet(privateKey, ethers.provider) : (await ethers.getSigners())[0];
    if (privateKey) console.log('Using deployer address:', signer.address);

    if (undefined == process.env.COLLECTION_URI_PREFIX || process.env.COLLECTION_URI_PREFIX === 'ipfs://__CID__/') {
        throw 'please set the COLLECTION_URI_PREFIX environment variable';
    }

    const contract = await NftContractProvider.getContract(signer);

    if ((await contract.uriPrefix() !== process.env.COLLECTION_URI_PREFIX)) {
        console.log("update the uri prefix to the collection uri prefix");
        await (await contract.setUriPrefix(process.env.COLLECTION_URI_PREFIX)).wait();
    }

    if (!await contract.revealed()) {
        console.log("reveal the collection");
        await (await contract.setRevealed(true)).wait();
    } else {
        console.log("the collection is already revealed!");
    }

    console.log("collection is now revealed!");
}

main().catch((error) =>{
    console.error(error);
    process.exitCode = 1;
})