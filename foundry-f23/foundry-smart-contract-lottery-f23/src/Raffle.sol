// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/**
 * @title A sample Raffle Contract
 * @author juangas
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */

contract Raffle is VRFConsumerBaseV2 {
    /**
     * Errors
     */

    error Raffle__NotEnoughEthSent();
    error Raffle__NotEnoughTime();
    error Raffle__EthTransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__NoPlayers();
    error Raffle_UpKeepNotNeeded(uint256, uint256, uint256);
    /**
     *
     * Enum
     */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /**
     * Events
     */
    event EnteredRaffle(address indexed newPlayerAdded);
    event NewWinner(address indexed winner, uint256 amount);
    event NewPerformUpKeepRequestId(uint256 indexed requestId);
    /**
     * Variables
     */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 2;

    address private immutable i_owner;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_entranceFee;
    address[] private s_players;
    uint256 private s_interval;
    uint256 private s_lastTimestamp;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;

    // @dev Duration of the lottery in seconds

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_owner = msg.sender;
        s_entranceFee = entranceFee;
        s_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    /**
     * Modifiers
     */
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert();
        }
        _;
    }

    modifier raffleStateOpen() {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        _;
    }

    function enterRaffle() external payable raffleStateOpen {
        if (msg.value < s_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    // 1. Get a random number
    // 2. Select the winner based on the random number
    /**
     * @dev This is the function that the Chainlink Automation nodes call
     * to see if it's time to pick a winner.
     * The following has to be true to return true:
     * 1. The time interval has passed.
     * 2. The raffle is at open state
     * 3. The contract has ETh (aka players)
     * 4. (Implicit) the subscription is funded with link
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /*performData */) {
        bool isOpened = s_raffleState == RaffleState(0);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        bool timeHasPassed = block.timestamp - s_lastTimestamp > s_interval;
        upkeepNeeded = (isOpened && hasPlayers && hasBalance && timeHasPassed);
        return (upkeepNeeded, "0x00");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        // 1 Request the RNG

        uint256 request_id = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit NewPerformUpKeepRequestId(request_id);
    }

    function fulfillRandomWords(
        uint256,
        uint256[] memory _randomWords
    ) internal override {
        uint256 s_randomNumber = _randomWords[0];
        uint256 indexPlayerWinner = s_randomNumber % s_players.length;
        address payable winner = payable(s_players[indexPlayerWinner]);
        s_recentWinner = winner;
        uint256 prize = address(this).balance;
        emit NewWinner(winner, prize);

        (bool callSuccess, ) = winner.call{value: prize}("");
        if (!callSuccess) {
            revert Raffle__EthTransferFailed();
        }
        // Restart the players and timestamp and befin of a new raffle
        resetRaffle();
    }

    function resetRaffle() internal {
        s_players = new address[](0);
        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    /**
     * Setter functions
     */

    function setEntranceFee(uint256 entranceFee) public onlyOwner {
        s_entranceFee = entranceFee;
    }

    function setInterval(uint256 interval) public onlyOwner {
        s_interval = interval;
    }

    /**
     * Getter Functions
     */

    /**
     * address private immutable i_owner;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_entranceFee;
    address[] private s_players;
    uint256 private s_interval;
    uint256 private s_lastTimestamp;
    address payable private s_recentWinner;
     */

    function getPlayers() external view returns (address[] memory) {
        return s_players;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLastTimestamp() external view returns (uint256) {
        return s_lastTimestamp;
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getEntranceFee() external view returns (uint256) {
        return s_entranceFee;
    }

    function getInterval() external view returns (uint256) {
        return s_interval;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    fallback() external {}
}
