// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { console } from "forge-std/console.sol";

import { Ethereum } from "lib/spark-address-registry/src/Ethereum.sol";

import { Script } from 'forge-std/Script.sol';

import { Deploy } from "../deploy/Deploy.sol";

contract DeployArbitrumOneExecutor is Script {

    function run() public {
        vm.createSelectFork(getChain("arbitrum_one").rpcUrl);

        vm.startBroadcast();

        address executor = Deploy.deployExecutor(0, 7 days);
        address receiver = Deploy.deployArbitrumReceiver(Ethereum.SPARK_PROXY, executor);

        console.log("executor deployed at:", executor);
        console.log("receiver deployed at:", receiver);

        Deploy.setUpExecutorPermissions(executor, receiver, msg.sender);

        vm.stopBroadcast();
    }

}

contract DeployBaseExecutor is Script {

    function run() public {
        vm.createSelectFork(getChain("base").rpcUrl);

        vm.startBroadcast();

        address executor = Deploy.deployExecutor(0, 7 days);
        address receiver = Deploy.deployOptimismReceiver(Ethereum.SPARK_PROXY, executor);

        console.log("executor deployed at:", executor);
        console.log("receiver deployed at:", receiver);

        Deploy.setUpExecutorPermissions(executor, receiver, msg.sender);

        vm.stopBroadcast();
    }

}

contract DeployUnichainExecutor is Script {

    function run() public {
        vm.createSelectFork(vm.envString("UNICHAIN_RPC_URL"));

        vm.startBroadcast();

        address executor = Deploy.deployExecutor(0, 7 days);
        address receiver = Deploy.deployOptimismReceiver(Ethereum.SPARK_PROXY, executor);

        console.log("executor deployed at:", executor);
        console.log("receiver deployed at:", receiver);

        Deploy.setUpExecutorPermissions(executor, receiver, msg.sender);

        vm.stopBroadcast();
    }

}

