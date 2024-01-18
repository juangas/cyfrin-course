// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console, StdCheats} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/Helper.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    /** Events */

    event EnteredRaffle(address indexed player);
    event NewWinner(address indexed winner, uint256 indexed amount);

    Raffle raffle;
    HelperConfig helperConfig;
    DeployRaffle deploy;
    address USER = makeAddr("user");
    uint256 constant INITIAL_BALANCE = 10 ether;
    uint256 constant ENTRANCE_FEE = 0.01 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    function setUp() external {
        deploy = new DeployRaffle();
        (raffle, helperConfig) = deploy.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,

        ) = helperConfig.activeNetworkConfig();
        vm.deal(USER, INITIAL_BALANCE);
    }

    function testRaffleInitializesInOpenState() public {
        assertEq(uint256(raffle.getRaffleState()), 0);
    }

    function testOwnnership() public {
        address owner = raffle.getOwner();
        assertEq(owner, msg.sender);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(USER);
        // Act
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        // Assert
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenEnter() public {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        assertEq(raffle.getPlayers()[0], USER);
    }

    function testEnterRaffle() public {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        assertNotEq(address(raffle).balance, 0);
        assertEq(raffle.getPlayers()[0], USER);
    }

    function testRaffleEmitEvent() public {
        vm.prank(USER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    function testRaffleWhenRaffleIsCalculating() public {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    function testRafflePickWinner() public {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
    }

    /**
     * CheckUpKeep tests
     */
    function testCheckUpKeepUpReturnsFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfItHaveNotPlayers() public {
        vm.deal(address(raffle), 1 ether);
        assert(address(raffle).balance > 0);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfStateIsNotOpen() public {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepWithNoTimePassed() public {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testCheckupKeepReturnsTrueIfAllTheParametersAreOkay() public {
        testFundVariousPlayers();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        assert(upKeepNeeded);
    }

    /**
     * PerformKeepUp tests
     */

    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() public {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
    }

    function testPerformUpKeepRevertIfCheckUpKeepReturnsFalse() public {
        uint256 currentBalance = 0;
        uint256 numberOfPlayers = 0;
        uint256 raffleState = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpKeepNotNeeded.selector,
                currentBalance,
                numberOfPlayers,
                raffleState
            )
        );
        vm.prank(USER);
        raffle.performUpkeep("");
    }

    function testFundVariousPlayers() public {
        uint160 startingIndex = 1;
        uint160 numberOfPlayers = 12;
        for (uint160 i = startingIndex; i <= numberOfPlayers; i++) {
            hoax(address(i));
            raffle.enterRaffle{value: ENTRANCE_FEE}();
        }

        assertEq(raffle.getPlayers().length, numberOfPlayers);
    }

    modifier userEnterRaffleAndTimePassed() {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitRequestId()
        public
        userEnterRaffleAndTimePassed
    {
        vm.recordLogs();
        raffle.performUpkeep(""); // emit RequestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[0];
        uint256 raffleState = uint256(raffle.getRaffleState());
        assertEq(raffleState, 1);
        assert(uint256(requestId) > 0);
    }

    function testPickWinner() public {
        testFundVariousPlayers();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.expectEmit(true, false, false, false);
        emit NewWinner(address(0), 12 * ENTRANCE_FEE);
        raffle.performUpkeep("");
        address winner = raffle.getRecentWinner();
        console.log("The winner is ", winner);
    }

    function testFullFillRandomWordsCannotBeCalledIfPerformUpKeepHasNot(
        uint256 randomRequestId
    ) public {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFullFillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        userEnterRaffleAndTimePassed
    {
        uint160 additionalEntrants = 5;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i <= additionalEntrants; i++) {
            address player = address(i);
            hoax(player, ENTRANCE_FEE);
            raffle.enterRaffle{value: ENTRANCE_FEE}();
            assertEq(address(i).balance, 0);
        }
        vm.recordLogs();
        raffle.performUpkeep(""); // emit RequestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        console.log("The Winner is ", raffle.getRecentWinner());

        // assertEq(
        //     address(entries[2].topics[0]).balance,
        //     (additionalEntrants + 1) * ENTRANCE_FEE
        // );

        //Assert
        assert(raffle.getRecentWinner() != address(0));
        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getPlayers().length == 0);
        assert(
            raffle.getRecentWinner().balance ==
                ENTRANCE_FEE * (additionalEntrants + 1)
        );
    }

    function testChangeInterval() public userEnterRaffleAndTimePassed {
        uint256 new_interval = interval * 2;
        vm.stopPrank();
        // console.log("Owner", raffle.getOwner());
        // console.log(address(this));
        // console.log(address(helperConfig));
        // console.log(address(deploy));
        // console.log(USER);
        vm.prank(msg.sender);
        raffle.setInterval(new_interval);
        vm.expectRevert();
        raffle.performUpkeep("");
    }
}
