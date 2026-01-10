// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {
    VRFConsumerBaseV2Plus
} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {
    VRFV2PlusClient
} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @title Raffle Smart Contract
/// @author cao hao
/// @notice This is a simple lotter smart contract for learning purpose how to use chainlink VRF
/// @dev non
contract Raffle is VRFConsumerBaseV2Plus {
    enum RaffleState {
        OPEN,
        REVEALING
    }

    modifier _onlyOwner() {
        require(msg.sender == i_owner, "only owner can call");
        _;
    }

    /* event declaration */
    event Raffle__EnterLottery(address player);
    event Raffle__WinLottery(address player);

    /* error declaration */
    error Raffle__AlreadyEntered();
    error Raffle__NotEnoughValue();
    error Raffle__NotOpen();
    error Raffle__RandomWordsError();
    error Raffle__PayFailed();
    error Raffle__NoParticipants();

    /* state variable declaration */
    uint256 private immutable i_ticketPrice;
    uint256 private immutable i_lotteryRoundInterval;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    address private immutable i_owner;
    mapping(address => bool) public s_participants;
    address[] public s_participantsArr;
    RaffleState private s_state;
    uint16 private constant VRF_CONFIRMATION = 3;
    uint32 private constant VRD_CALLBACK_GAS_LIMIT = 100_000;

    constructor(uint256 tickPrice, uint256 interval, uint256 subscriptionId, address coordinatorAddr, bytes32 keyHash)
        VRFConsumerBaseV2Plus(coordinatorAddr)
    {
        i_ticketPrice = tickPrice;
        i_lotteryRoundInterval = interval;
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_owner = msg.sender;
        s_state = RaffleState.OPEN;
    }

    function participate() external payable {
        // 1. make sure condition is met
        if (s_participants[msg.sender] == true) {
            revert Raffle__AlreadyEntered();
        } else if (msg.value < i_ticketPrice) {
            revert Raffle__NotEnoughValue();
        } else if (s_state != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }

        // 2. set msg.sender as participant
        s_participants[msg.sender] = true;
        s_participantsArr.push(msg.sender);

        // 3. transfer back the remaining value
        uint256 remainingValue = msg.value - i_ticketPrice;
        if (remainingValue > 0) {
            msg.sender.call{value: remainingValue}("");
        }

        // 4. emit the event
        emit Raffle__EnterLottery(msg.sender);
    }

    // it should be only owner
    function revealResult() external _onlyOwner returns (uint256) {
        // 1. make sure the condition is met
        if (s_state != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        } else if (s_participantsArr.length == 0) {
            revert Raffle__NoParticipants();
        }

        // 2. change the state to revealing
        s_state = RaffleState.REVEALING;

        // 3. use chainlink VRF to get a random number
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: VRF_CONFIRMATION,
                callbackGasLimit: VRD_CALLBACK_GAS_LIMIT,
                numWords: 1,
                // nativePayment set to `false` mean pay in LINK
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // 0. make sure the condition is met
        if (randomWords.length != 1) {
            revert Raffle__RandomWordsError();
        }

        // 1. select the winner and pay (use simple modulo operater)
        uint256 selectedIndex = randomWords[0] % s_participantsArr.length;
        address payable winner = payable(s_participantsArr[selectedIndex]);
        (bool result,) = winner.call{value: address(this).balance}("");
        if (result == false) {
            revert Raffle__PayFailed();
        }

        // 2. restore the variables
        for (uint256 i = 0; i < s_participantsArr.length; i++) {
            delete s_participants[s_participantsArr[i]];
        }
        delete s_participantsArr;
        s_state = RaffleState.OPEN;

        // 3. emit event
        emit Raffle__WinLottery(winner);
    }
}
