// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {MyERC20} from "../src/MyERC20.sol";
import {IERC20Errors} from "../lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract MyERC20Test is Test {

    uint private constant INIT_BALANCE = 100;

    MyERC20 private erc20;
    Account contractOwner = makeAccount("contract_owner");
    Account userA = makeAccount("userA");
    Account userB = makeAccount("userB");
    Account hacker = makeAccount("hacker");

    function setUp() external {
        console.log("setup");
        vm.prank(contractOwner.addr);
        erc20 = new MyERC20("testETH", "tETH", INIT_BALANCE);
    }

    function testBalanceOf() external view{
        uint256 balance = erc20.balanceOf(contractOwner.addr);
        vm.assertEq(balance, INIT_BALANCE * 10 ** erc20.decimals());
    }

    function testTransferSuccess() external{
        // if just call vm.prank , it will fail , because msg.sender is contractOwner
        // only for `erc20.decimals()`
        vm.startPrank(contractOwner.addr);
        erc20.transfer(userA.addr, 1 ether);
        vm.stopPrank();
    }

    function testTransferFailedBecauseInsufficientBalance() external {
        vm.prank(userA.addr);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, 
            userA.addr, 0, 1 ether));
        erc20.transfer(userB.addr, 1 ether);
    }

    function testAddBlackListSuccess() external {
        vm.startPrank(contractOwner.addr);
        erc20.updateBlacklist(hacker.addr, true);
        vm.assertEq(erc20.isInBlackList(hacker.addr), true);
        vm.stopPrank();
    }

    function testAddBlackListFailedBecauseCallerNotOwner() external {
        vm.startPrank(userA.addr);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, userA.addr));
        erc20.updateBlacklist(hacker.addr, true);
        vm.stopPrank();
    }

}