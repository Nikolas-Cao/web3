// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {FundMe} from "../src/FundMe.sol";
import {Test} from "@forge-std/src/Test.sol";
import {console} from "@forge-std/src/console.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FuneMeTest is Test{

    FundMe fundMe;
    Account user = makeAccount("user");
    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        console.log("deply contact address : ");
        console.log(address(deploy));
        console.log("test contact adress : ");
        console.log(address(this));
        console.log("msg sender : ");
        console.log(msg.sender);
        fundMe = deploy.run();
        vm.deal(user.addr, 500 ether);
    }

    function testVersion() external {
        uint256 version = fundMe.getVersion();
        console.log(version);
        assertEq(version, 4);
    }

    function testOwner() external {
        // when execute with `forge test` 
        // if it wrapped with vm.startBroadcast(); and vm.stopBroadcast(); , in the constrcutor of contract , the msg.sender will be the address of the created contract
        // else if it outside of vm.xxx and vm.xxx , the msg.sender remain the same with who call the test(who deploy the test contract)
        address owner = fundMe.getOwner();
        assertEq(owner, msg.sender);
    }

    function testFundFailed() external {
        vm.prank(user.addr);
        vm.expectRevert();
        fundMe.fund{value : 5}();
    }

    function testFundSuccess() external {
        vm.prank(user.addr);
        fundMe.fund{value:5 ether}();
        uint256 money = fundMe.getAddressToAmountFunded(user.addr);
        assertEq(money, 5 ether);
    }
}