// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { Ethereum } from "lib/spark-address-registry/src/Ethereum.sol";

import { Script } from 'forge-std/Script.sol';

import { Deploy } from "../deploy/Deploy.sol";

contract DeployBaseExecutor is Script {

    function run() public {
        address executor = Deploy.deployExecutor(100, 1000);
        address receiver = Deploy.deployOptimismReceiver(Ethereum.SPARK_PROXY, executor);

        Deploy.setUpExecutorPermissions(executor, receiver);
    }

}
