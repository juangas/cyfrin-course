// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console, StdCheats} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    uint256 number = 0;
    FundMe fundMe;
    DeployFundMe deployFundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant INITIAL_BALANCE = 10 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        console.log("Chain_id: ", block.chainid);
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, INITIAL_BALANCE);
    }

    function testGetVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        // uint256 version = fundMe.getVersion();
    }

    function testFundMe() public {
        address payable recipient = payable(fundMe);
        (bool callSuccess, ) = recipient.call{value: 2500000000000000}(
            abi.encodeWithSignature("fund()")
        );
        assertEq(callSuccess, bool(true));
        // console.log("callSuccess?", callSuccess);
    }

    function testFundMeFailWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmount(USER);
        assertEq(amountFunded, SEND_VALUE);
        vm.stopPrank();
    }

    function testAddsFundersToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(USER, funder);
        vm.stopPrank();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();

        address owner = fundMe.i_owner();
        vm.prank(owner);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // console.log(startingOwnerBalance, startingFundMeBalance);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 finalOwnerBalance = fundMe.getOwner().balance;
        uint256 finalFundMeBalance = address(fundMe).balance;

        assertEq(
            finalOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );

        assertEq(finalFundMeBalance, 0);
    }

    function testWithdrawWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint startingOwnerBalance = fundMe.getOwner().balance;
        uint startingFundBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint finalOwnerBalance = fundMe.getOwner().balance;
        uint finalFundBalance = address(fundMe).balance;

        assertEq(finalOwnerBalance, startingOwnerBalance + startingFundBalance);
        assert(finalFundBalance == 0);
    }

    function testCheaperWithdrawWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint startingOwnerBalance = fundMe.getOwner().balance;
        uint startingFundBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        uint finalOwnerBalance = fundMe.getOwner().balance;
        uint finalFundBalance = address(fundMe).balance;

        assertEq(finalOwnerBalance, startingOwnerBalance + startingFundBalance);
        assert(finalFundBalance == 0);
    }
}
