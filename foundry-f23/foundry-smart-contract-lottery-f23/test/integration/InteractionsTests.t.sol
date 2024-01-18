// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/Helper.s.sol";

contract InteractionsTests {
    DeployRaffle deploy;

    function setUp() external {
        deploy = new DeployRaffle();
    }

    function testDeployCorrectly() public {
        (Raffle raffle, HelperConfig helper) = deploy.run();
    }
}
