// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract OurTokenTest is StdCheats, Test {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    error ERC20InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );

    OurToken public ourToken;
    DeployOurToken public deployer;

    uint256 STARTING_BALANCE = 1000 ether;

    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();
        vm.deal(alice, 1 ether); // Provide some Ether to Alice for transactions
        vm.deal(bob, 1 ether); // Provide some Ether to Bob for transactions
        vm.startPrank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
        ourToken.transfer(alice, STARTING_BALANCE);
        vm.stopPrank();
    }

    function testInitialSupply() public {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    // function testUsersCantMint() public {
    //     vm.expectRevert();
    //     ourToken._mint(address(this), 1);
    // }

    function testApproveAndAllowance() public {
        vm.startPrank(alice);
        ourToken.approve(bob, 100);
        vm.stopPrank();

        uint256 allowance = ourToken.allowance(alice, bob);
        assertEq(allowance, 100, "Allowance should be correctly set to 100");
    }

    function testTransfer() public {
        uint256 aliceInitialBalance = ourToken.balanceOf(alice);
        uint256 bobInitialBalance = ourToken.balanceOf(bob);

        // Alice sends tokens to Bob
        vm.startPrank(alice);
        ourToken.transfer(bob, 100);
        vm.stopPrank();

        uint256 aliceFinalBalance = ourToken.balanceOf(alice);
        uint256 bobFinalBalance = ourToken.balanceOf(bob);

        assertEq(
            aliceFinalBalance,
            aliceInitialBalance - 100,
            "Alice's balance should decrease by 100"
        );
        assertEq(
            bobFinalBalance,
            bobInitialBalance + 100,
            "Bob's balance should increase by 100"
        );
    }

    function testTransferFrom() public {
        uint256 bobInitialBalance = ourToken.balanceOf(bob);
        // Alice approves Bob to spend on her behalf
        vm.startPrank(alice);
        ourToken.approve(bob, 200);
        vm.stopPrank();

        // Bob transfers from Alice to himself
        vm.startPrank(bob);
        ourToken.transferFrom(alice, bob, 200);
        vm.stopPrank();

        uint256 allowanceAfter = ourToken.allowance(alice, bob);
        uint256 bobBalance = ourToken.balanceOf(bob);

        assertEq(allowanceAfter, 0, "Allowance should be reduced to 0");
        assertEq(
            bobBalance,
            bobInitialBalance + 200,
            "Bob's balance should be 200"
        );
    }

    function testFailTransferNotEnoughBalance() public {
        // bool transferStatus = false;
        uint256 initialBalanceAlice = ourToken.balanceOf(alice);

        // Attempt to transfer more tokens than Alice has
        vm.startPrank(alice);
        ourToken.transfer(bob, initialBalanceAlice + 1);
        vm.stopPrank();
    }

    // Test to check if the Transfer event is emitted correctly
    function testTransferEvent() public {
        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit Transfer(alice, bob, 100);
        ourToken.transfer(bob, 100);
        vm.stopPrank();
    }

    // Test to check if the Approval event is emitted correctly
    function testApprovalEvent() public {
        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit Approval(alice, bob, 100);
        ourToken.approve(bob, 100);
        vm.stopPrank();
    }
}
