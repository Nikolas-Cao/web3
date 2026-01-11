# Introduction
This is a simple foundry project to learn how to implement a lottery smart contract .
The main point is about how to use ChainLink VRF to get random numbers in a secure way.

# Quick Start
1. install dependency
   ```
   forge install smartcontractkit/chainlink-brownie-contracts@1.3.0
   ```
2. test the contract
    ```
    forge test
    ```
3. deploy to sepolia testnet
   ```
   1. prepare environment variables
   source .env

   2. try compile
   forge build

   3. simulate deployment (no gas spent)
   forge script script/DeployCounter.s.sol --fork-url sepolia

   4. real deployment
   forge script script/DeployCounter.s.sol \
   --rpc-url $SEPOLIA_RPC_URL \
   --private-key $A \
   --broadcast \
   -vvvv
   ```

# troubleshooting
1. if you write `.env` file in vscode or any other editor (any windows app) , when execute make command in git bash or wsl, it may not work because of the line ending issue.
   > you can use `dos2unix .env` command to convert the file to unix format.