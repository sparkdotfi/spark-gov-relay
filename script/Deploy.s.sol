// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { Script } from 'forge-std/Test.sol';

import { Deploy } from "../deploy/Deploy.sol";

contract DeployBaseExecutor is Script {

    function run() public override {
        address executor = Deploy.deployExecutor(100, 1000);

        address receiver = Deploy.deployOptimismReceiver(address(this), executor);
    }
}
