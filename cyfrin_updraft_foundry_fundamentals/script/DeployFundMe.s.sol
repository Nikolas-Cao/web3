// SPDX-License-Identifier : MIT

pragma solidity ^0.8.19;

import {Script} from "@forge-std/src/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {ConfigHelper} from "./ConfigHelper.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        ConfigHelper config = new ConfigHelper();
        address priceAddress = config.priceAddress();

        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceAddress);
        vm.stopBroadcast();
        return fundMe;
    }
}