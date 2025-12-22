// SPDX-License-Identifier : MIT
pragma solidity ^0.8.19;

import {Script} from "@forge-std/src/Script.sol";
import {console} from "@forge-std/src/console.sol";
import {MockV3Aggregator} from "./mock/MockV3Aggregator.sol";

contract ConfigHelper is Script {
    struct NetworkConfig {
        address priceFeedAddress;
    }

    NetworkConfig public priceAddress;

    constructor() {
        console.log(block.chainid);
        if (block.chainid == 11155111) {
            priceAddress = getSepoliaConfig();
        } else {
            priceAddress = getAnvilConfig();
        }
    }

    function getSepoliaConfig() private pure returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({
            priceFeedAddress : 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return config;
    }

    function getAnvilConfig() private returns (NetworkConfig memory) {
        vm.startBroadcast();
        MockV3Aggregator mock = new MockV3Aggregator(8, 2000e8);
        vm.stopBroadcast();

        NetworkConfig memory config = NetworkConfig({
            priceFeedAddress : address(mock)
        });
        return config;
    }
}