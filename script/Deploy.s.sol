// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { console } from "forge-std/console.sol";

import { Ethereum } from "lib/spark-address-registry/src/Ethereum.sol";

import { Script } from 'forge-std/Script.sol';

import { Deploy } from "../deploy/Deploy.sol";

contract DeployBaseExecutor is Script {

    function run() public {
        vm.startBroadcast();

        console.log("msg.sender   ", msg.sender);
        console.log("tx.origin    ", tx.origin);
        console.log("address(this)", address(this));

        address executor = Deploy.deployExecutor(100, 1000);
        address receiver = Deploy.deployOptimismReceiver(Ethereum.SPARK_PROXY, executor);

        Deploy.setUpExecutorPermissions(executor, receiver, msg.sender);

        vm.stopBroadcast();
    }

}
