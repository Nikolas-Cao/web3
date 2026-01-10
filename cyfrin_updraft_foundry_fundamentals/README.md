# Foundry

This is the page that conclude what I learn from [Cyfrin Updraft](https://updraft.cyfrin.io/courses/foundry).
Just summary everything up .
You can see some code I write during learning . ex [FundMe.sol](./src/FundMe.sol)

## prerequisite
To use foundry , we need linux environment .
Since my pc is windows OS , so that I install and use WSL .

## Components
In my understanding , fundry is a framework that consist of four components
- forge : a development tool that you can run `build` , `compile` , `test` , `script`
- anvil : a tool that run a lock blockchain . a lock blockchain mean's one or several running node that can handle transactions . 
- cast : a tool that we can `interact` with bloack chain via command line , usualy send transaction to the blockchian . for me , it looks like the `curl` command to interact with server . 
- chisel : a tool that you can execute solidty code line by line like chrome console for js

this is the official explanation : [foundry official link](https://getfoundry.sh/introduction/getting-started)


### forge
this is very basic and important part of foundry .
* `forge build [OPTIONS] [PATHS]...` : build the targe solidity file , example `forge build src/FundMe.sol` 
* `forge script [OPTIONS] <PATH> [ARGS]` : run the script that written by solidity . one usage is to deploy the smart contract . in script , you can use some cheatcode like vm.startBroadcast() , this mean the transaction will be send to blockchain .


## Thoughts
During learning , I find few pain point of foundry framework .
Maybe they have solution already , but I didn't know it yet
- it is hard to manage dependency .
> when you want to use the util/lib smart contract that developed by other team/people , 
> you usually have following ways
>  1. new a file by yourself and copy the smart contract code to it
>  2. use `forge install OpenZeppelin/openzeppelin-contracts` and the use it by `import "@openzeppelin/contracts/token/ERC20/ERC20.sol"` , for me `@` don't work , I need specify the relative path.
