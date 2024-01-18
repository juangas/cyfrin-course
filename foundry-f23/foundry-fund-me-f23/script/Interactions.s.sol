// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {Script, console} from "forge-std/Script.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.1 ether;

    function fundFundMe(address mostRecentDeployment) public {
        FundMe fundMe = FundMe(payable(mostRecentDeployment));
        vm.startBroadcast();
        fundMe.fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Fund me with %s", SEND_VALUE);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        fundFundMe(mostRecentlyDeployed);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        FundMe fundMe = FundMe(payable(mostRecentlyDeployed));
        vm.startBroadcast();
        fundMe.withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        withdrawFundMe(mostRecentlyDeployed);
    }
}
