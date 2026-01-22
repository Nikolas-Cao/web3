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

    /* test for transfer */
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

    /* test for black list */
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

    function testBlackListAddressCanNotTransfer() external {
        vm.startPrank(contractOwner.addr);
        erc20.updateBlacklist(userA.addr, true);
        vm.stopPrank();

        // send from A(black list) to B
        vm.startPrank(userA.addr);
        vm.expectRevert(abi.encodeWithSelector(MyERC20.MyERC20__AddressInBlackList.selector, userA.addr));
        erc20.transfer(userB.addr, 0.1 ether);
        vm.stopPrank();

        // send from B to A(black list)
        vm.startPrank(userB.addr);
        vm.expectRevert(abi.encodeWithSelector(MyERC20.MyERC20__AddressInBlackList.selector, userA.addr));
        erc20.transfer(userA.addr, 0.1 ether);
        vm.stopPrank();
    }

    function testCanTransferToSelf() external {
        vm.startPrank(contractOwner.addr);
        // approve userA spent 1 ether from contractOwner
        erc20.approve(userA.addr, 1 ether);
        vm.stopPrank();

        vm.startPrank(userA.addr);
        assertEq(erc20.allowance(contractOwner.addr, userA.addr), 1 ether);

        // userA transfer 1 ether from contractOwner to self
        erc20.transferFrom(contractOwner.addr, userA.addr, 1 ether);
        assertEq(erc20.balanceOf(userA.addr), 1 ether);

        erc20.transfer(userA.addr, 1 ether);
        assertEq(erc20.balanceOf(userA.addr), 1 ether);
        vm.stopPrank();
    }

    function testCanNotTransferFromSelfToAnotherUser() external {
        vm.startPrank(contractOwner.addr);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, contractOwner.addr, 0, 1 ether));
        erc20.transferFrom(contractOwner.addr, contractOwner.addr, 1 ether);
        vm.stopPrank();
    }

    /* test for vote */
    function testDelegateToSelfSuccess() external {
        vm.startPrank(contractOwner.addr);
        erc20.delegate(contractOwner.addr);
        assertEq(erc20.getVotes(contractOwner.addr), erc20.balanceOf(contractOwner.addr));
        vm.stopPrank();
    }

    function testDelegateToOtherPersonSuccess() external {
        vm.startPrank(contractOwner.addr);
        erc20.delegate(userA.addr);
        assertEq(erc20.getVotes(userA.addr), erc20.balanceOf(contractOwner.addr));

        erc20.transfer(userB.addr, 20 ether);
        // make sure that after transfer the money , the vote of delegate also updated
        assertEq(erc20.getVotes(userA.addr), erc20.balanceOf(contractOwner.addr));
        vm.stopPrank();
    }

    function testGetPassVotesSuccess() external {
        vm.startPrank(contractOwner.addr);
        // at this time , userA.addr suppose to have 100 ether votes
        erc20.delegate(userA.addr);
        uint256 pastTimeA = block.number;

        // block.number increase
        vm.warp(block.timestamp + 100 seconds);
        vm.roll(block.number + 1);

        // at this time , userA.addr suppose to have 80 ether votes
        erc20.transfer(userB.addr, 20 ether);
        uint256 pastTimeB = block.number;

        // make time goes 100 seconds
        vm.warp(block.timestamp + 100 seconds);
        vm.roll(block.number + 1);

        console.log("pastTimeA : ", pastTimeA);
        console.log("pastTimeB : ", pastTimeB);
        console.log("block.timestamp : ", block.timestamp);

        // the snapshot is based on block.number , not block.timestamp
        assertEq(erc20.getPastVotes(userA.addr, pastTimeA), 100 ether);
        assertEq(erc20.getPastVotes(userA.addr, pastTimeB), 80 ether);

        vm.stopPrank();
    }
}