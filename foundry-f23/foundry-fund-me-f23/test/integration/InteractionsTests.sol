// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console, StdCheats} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract FundMeTestIntegration is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant INITIAL_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
    }

    function testUsersCanFundInteractions() public {
        FundFundMe ffm = new FundFundMe();
        // fundMe.fund{value: INITIAL_BALANCE - 1}();
        ffm.fundFundMe(address(fundMe));
        // ffm.run();

        WithdrawFundMe wfm = new WithdrawFundMe();
        wfm.withdrawFundMe(address(fundMe));
    }
}
