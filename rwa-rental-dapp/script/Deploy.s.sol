// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/MockUSDC.sol";
import "../contracts/RWA1155.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        MockUSDC usdc = new MockUSDC();
        RWA1155 rwa = new RWA1155(address(usdc));

        vm.stopBroadcast();
    }
}
