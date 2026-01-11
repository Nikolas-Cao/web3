// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {console} from "../lib/forge-std/src/console.sol";

contract RaffleDeploySepolia is Script{
    function run() external {
        uint256 subId = vm.envUint("VRF_SUB_ID");
        address coordinator = vm.envAddress("VRF_COORDINATOR_ADDR");
        bytes32 keyHash = vm.envBytes32("VRF_KEY_HASH");

        vm.startBroadcast();

        // set interval as 1 mins for test
        Raffle raffle = new Raffle(0.01 ether, 1 minutes, subId, coordinator, keyHash);
        
        vm.stopBroadcast();

        // 可选：在控制台打印部署地址（非常实用）
        console.log("raffle deployed to:", address(raffle));
    }
}