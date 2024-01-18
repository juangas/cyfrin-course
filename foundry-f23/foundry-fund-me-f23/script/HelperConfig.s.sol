// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggreagtor.sol";
struct NetworkConfig {
    address priceFeed;
}

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid == 137) {
            activeNetworkConfig = getPolygonEthConfig();
        } else if (block.chainid == 42161) {
            activeNetworkConfig = getArbitrumEthConfig();
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // priceFeed
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // priceFeed
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }

    function getPolygonEthConfig() public pure returns (NetworkConfig memory) {
        // priceFeed
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0xF9680D99D6C9589e2a93a78A04A279e509205945
        });
        return mainnetConfig;
    }

    function getArbitrumEthConfig() public pure returns (NetworkConfig memory) {
        // priceFeed
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
        });
        return mainnetConfig;
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        // priceFeed address
        // 1. Deploy the mocks
        // 2. Return the mock address
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();
        NetworkConfig memory mockNetworkConfig = NetworkConfig({
            priceFeed: address(mockV3Aggregator)
        });
        console.log("Address mock contract: ", address(mockV3Aggregator));
        return mockNetworkConfig;
    }
}
