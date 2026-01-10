// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/Script.sol";
import {
    VRFCoordinatorV2_5Mock
} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Raffle} from "../src/Raffle.sol";
import {console} from "../lib/forge-std/src/console.sol";

contract RaffleTest is Test {
    Account subOwner = makeAccount("subOnwer");
    Account player1 = makeAccount("player1");
    Account player2 = makeAccount("player2");
    Account player3 = makeAccount("player3");
    VRFCoordinatorV2_5Mock coordinator;
    Raffle raffle;

    function toEtherString(uint256 weiAmount) internal pure returns (string memory) {
        uint256 etherPart = weiAmount / 1 ether;
        uint256 remainder = weiAmount % 1 ether;

        // 保留 4 位小数（1 ether = 10^18 wei，所以 / 10^14 得到 4 位）
        uint256 decimalPart = remainder / 1e14;

        string memory decimalStr = vm.toString(decimalPart);

        // 补齐 4 位（如果小数部分不足 4 位）
        if (decimalPart == 0) {
            decimalStr = "0000";
        } else if (decimalPart < 10) {
            decimalStr = string.concat("000", decimalStr);
        } else if (decimalPart < 100) {
            decimalStr = string.concat("00", decimalStr);
        } else if (decimalPart < 1000) {
            decimalStr = string.concat("0", decimalStr);
        }

        // 去掉末尾无意义的 0
        while (bytes(decimalStr).length > 0 && bytes(decimalStr)[bytes(decimalStr).length - 1] == bytes("0")[0]) {
            decimalStr = substring(decimalStr, 0, bytes(decimalStr).length - 1);
        }
        // 如果小数部分全 0，就不显示小数点
        if (bytes(decimalStr).length == 0) {
            return vm.toString(etherPart);
        }

        return string.concat(vm.toString(etherPart), ".", decimalStr);
    }

    // 辅助函数：substring（Solidity 没有内置，需要自己实现）
    function substring(string memory str, uint256 start, uint256 end) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = strBytes[i];
        }
        return string(result);
    }

    function setUp() external {
        vm.deal(subOwner.addr, 100 ether);
        vm.deal(player1.addr, 100 ether);
        vm.deal(player2.addr, 100 ether);
        vm.deal(player3.addr, 100 ether);

        bytes32 keyHash = 0x0;

        vm.startPrank(subOwner.addr);
        coordinator = new VRFCoordinatorV2_5Mock(0.25 ether, 1e9, 1 ether);
        uint256 subId = coordinator.createSubscription();
        raffle = new Raffle(0.01 ether, 24 * 60 * 60 seconds, subId, address(coordinator), keyHash);
        coordinator.addConsumer(subId, address(raffle));
        coordinator.fundSubscription(subId, 10 ether);
        coordinator.fundSubscriptionWithNative{value: 10 ether}(subId);
        vm.stopPrank();
    }

    function testParticipate() external {
        vm.prank(player1.addr);
        raffle.participate{value: 0.01 ether}();
    }

    function testParticipateNotEnoughValue() external {
        vm.prank(player1.addr);
        vm.expectRevert();
        raffle.participate{value: 0.001 ether}();
    }

    function testMultiParticipant() external {
        vm.startPrank(player1.addr);
        raffle.participate{value: 0.01 ether}();
        vm.expectRevert();
        raffle.participate{value: 0.01 ether}();
        vm.stopPrank();
    }

    function testRevealResultNoParticipant() external {
        vm.prank(subOwner.addr);
        vm.expectRevert();
        raffle.revealResult();
    }

    function testRevealResultSuccess() external {
        vm.prank(player1.addr);
        raffle.participate{value: 0.02 ether}();
        console.log("player1 before balance :");
        console.log(toEtherString(player1.addr.balance));

        vm.prank(player2.addr);
        raffle.participate{value: 0.01 ether}();
        console.log("player2 before balance :");
        console.log(toEtherString(player2.addr.balance));

        vm.prank(player3.addr);
        raffle.participate{value: 0.01 ether}();
        console.log("player3 before balance :");
        console.log(toEtherString(player3.addr.balance));

        vm.prank(subOwner.addr);
        uint256 requestId = raffle.revealResult();
        vm.prank(subOwner.addr);
        coordinator.fulfillRandomWords(requestId, address(raffle));

        console.log("player1 after balance :");
        console.log(toEtherString(player1.addr.balance));

        console.log("player2 after balance :");
        console.log(toEtherString(player2.addr.balance));

        console.log("player3 after balance :");
        console.log(toEtherString(player3.addr.balance));
    }
}
