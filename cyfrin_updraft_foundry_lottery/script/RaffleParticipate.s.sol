// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {console} from "../lib/forge-std/src/console.sol";

contract RaffleParticipate is Script{
    function run() external {
        vm.startBroadcast();
        Raffle raffle = Raffle(0x4cB1a2A43B8Abffd6Cc8579Ef0c806E797dc689f);
        raffle.participate{value : 0.01 ether}();
        vm.stopBroadcast();
    }
}