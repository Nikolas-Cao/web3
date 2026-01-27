// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {SimpleDex} from "../src/SimpleDex.sol";
import {MyERC20} from "../src/MyERC20.sol";

contract SimpleDexTest is Test {
    SimpleDex dex;
    MyERC20 token0;
    MyERC20 token1;

    Account owner = makeAccount("owner");
    Account userA = makeAccount("userA");
    Account userB = makeAccount("userB");

    function setUp() external {
        vm.startPrank(owner.addr);
        token0 = new MyERC20("token0", "mETH", 100);
        token1 = new MyERC20("token1", "wETH", 100);
        dex = new SimpleDex(address(token0), address(token1));
        vm.stopPrank();
    }

    function _transferToA(uint256 amount0, uint256 amount1) private {
        vm.prank(owner.addr);
        token0.transfer(userA.addr, amount0);
        vm.prank(owner.addr);
        token1.transfer(userA.addr, amount1);
    }

    function _transferToB(uint256 amount0, uint256 amount1) private {
        vm.prank(owner.addr);
        token0.transfer(userB.addr, amount0);
        vm.prank(owner.addr);
        token1.transfer(userB.addr, amount1);
    }

    // test add liquidity
    function testAddLiquiditySuccess() public {
        vm.startPrank(owner.addr);
        // 1. owner add liquidity
        uint256 token0Cnt = token0.balanceOf(owner.addr);
        uint256 token1Cnt = token1.balanceOf(owner.addr);
        uint256 shareCnt = dex.balanceOf(owner.addr);

        uint256 amount0 = 1 ether;
        uint256 amount1 = 2 ether;
        token0.approve(address(dex), amount0);
        token1.approve(address(dex), amount1);
        uint256 addedShare = dex.addLiquidity(amount0, amount1, 0, 0);

        // 2. check share and token count are right
        uint256 token0CntAfter = token0.balanceOf(owner.addr);
        uint256 token1CntAfter = token1.balanceOf(owner.addr);
        uint256 shareCntAfter = dex.balanceOf(owner.addr);

        vm.assertEq(token0Cnt - amount0, token0CntAfter);
        vm.assertEq(token1Cnt - amount1, token1CntAfter);
        vm.assertEq(shareCnt + addedShare, shareCntAfter);

        vm.stopPrank();
    }

    function testAddLiquidityFailedBecauseOfZero() public {
        vm.startPrank(owner.addr);
        vm.expectRevert();
        uint256 addedShare = dex.addLiquidity(0, 0, 0, 0);

        vm.stopPrank();
    }

    function testAddLiquiditySuccessWithTinyValue() public {
        vm.startPrank(owner.addr);
        // 1. owner add liquidity
        uint256 token0Cnt = token0.balanceOf(owner.addr);
        uint256 token1Cnt = token1.balanceOf(owner.addr);
        uint256 shareCnt = dex.balanceOf(owner.addr);

        uint256 amount0 = 1;
        uint256 amount1 = 2;
        token0.approve(address(dex), amount0);
        token1.approve(address(dex), amount1);
        uint256 addedShare = dex.addLiquidity(amount0, amount1, 0, 0);

        // 2. check share and token count are right
        uint256 token0CntAfter = token0.balanceOf(owner.addr);
        uint256 token1CntAfter = token1.balanceOf(owner.addr);
        uint256 shareCntAfter = dex.balanceOf(owner.addr);

        vm.assertEq(token0Cnt - amount0, token0CntAfter);
        vm.assertEq(token1Cnt - amount1, token1CntAfter);
        vm.assertEq(shareCnt + addedShare, shareCntAfter);

        vm.stopPrank();
    }

    function testAddLiquiditySuccessTwice() public {
        testAddLiquiditySuccess();
        testAddLiquiditySuccess();
        console.log("owner token0 cnt : ", token0.balanceOf(owner.addr));
        console.log("owner token1 cnt : ", token1.balanceOf(owner.addr));
    }

    function testAddLiquiditySuccessByUserA() public {
        testAddLiquiditySuccess();
        _transferToA(20 ether, 20 ether);

        vm.startPrank(userA.addr);
        token0.approve(address(dex), 20 ether);
        token1.approve(address(dex), 20 ether);

        uint256 share = dex.addLiquidity(2 ether, 2 ether, 0, 0);

        vm.assertEq(token0.balanceOf(userA.addr), 20 ether - 1 ether);
        vm.assertEq(token1.balanceOf(userA.addr), 20 ether - 2 ether);
        vm.assertEq(dex.balanceOf(owner.addr), dex.balanceOf(userA.addr));

        vm.stopPrank();
    }

    function testAddLiquidityFailedBecauseOfSlipping() public {
        testAddLiquiditySuccess();

        vm.startPrank(owner.addr);
        vm.expectRevert();
        dex.addLiquidity(2, 2, 2, 2);

        vm.expectRevert();
        dex.addLiquidity(1,4,1,4);

        vm.stopPrank();
    }

    // test remove liquidity
    function testRemoveLiquiditySuccess() public {
        testAddLiquiditySuccess();

        vm.startPrank(owner.addr);
        uint256 share = dex.balanceOf(owner.addr);
        dex.removeLiquidity(share);

        vm.assertEq(dex.balanceOf(owner.addr), 0);
        vm.assertEq(token0.balanceOf(owner.addr), 100 ether);
        vm.assertEq(token1.balanceOf(owner.addr), 100 ether);

        vm.stopPrank();
    }

    function testRemoveLiquidityFailedBecauseOfInSufficientShare() public {
        vm.prank(userA.addr);
        vm.expectRevert();
        dex.removeLiquidity(20);
    }

    // test swap
    function testSwapSuccess() public{
        testAddLiquiditySuccess();
        _transferToA(20 ether, 20 ether);

        vm.startPrank(userA.addr);
        token0.approve(address(dex), 2 ether);
        uint256 amountOut = dex.swap(address(token0), 2 ether, uint256(4 ether * 997) / 3000);
        vm.stopPrank();
    }

    function testSwapFailedBecauseOfInSufficientToken() public {
        testAddLiquiditySuccess();

        _transferToA(20 ether, 20 ether);
        vm.startPrank(userA.addr);
        token0.approve(address(dex), 2 ether);
        vm.expectRevert();
        uint256 amountOut = dex.swap(address(token0), 3 ether, uint256(4 ether * 997) / 3000);
        vm.stopPrank();
    }

    function testSwapFailedBecauseOfNoLiquidity() public {
        _transferToA(20 ether, 20 ether);
        vm.startPrank(userA.addr);
        token0.approve(address(dex), 2 ether);
        vm.expectRevert();
        uint256 amountOut = dex.swap(address(token0), 2 ether, uint256(4 ether * 997) / 3000);
        vm.stopPrank();
    }

    function testSwapFailedBecauseOfInvalidTokenAddress() public {
        vm.prank(owner.addr);
        vm.expectRevert();
        dex.swap(address(0xa), 10, 0);
    }

    function testSwapFailedBecauseOfSlipping() public {
        testAddLiquiditySuccess();
        _transferToA(20 ether, 20 ether);
        vm.startPrank(userA.addr);
        token0.approve(address(dex), 1 ether);
        vm.expectRevert();
        dex.swap(address(token0), 1 ether, 2 ether);
        vm.stopPrank();
    }
}
