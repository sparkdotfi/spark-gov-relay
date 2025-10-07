// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { console } from "forge-std/console.sol";

import { Ethereum } from "lib/spark-address-registry/src/Ethereum.sol";

import { LZForwarder } from "lib/xchain-helpers/src/forwarders/LZForwarder.sol";

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

contract DeployOptimismExecutor is Script {

    function run() public {
        vm.createSelectFork(getChain("optimism").rpcUrl);

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

contract DeployAvalancheExecutor is Script {

    function run() public {
        vm.createSelectFork(getChain("avalanche").rpcUrl);

        vm.startBroadcast();

        address executor = Deploy.deployExecutor(0, 7 days);
        address receiver = Deploy.deployLZReceiver({
            destinationEndpoint : LZForwarder.ENDPOINT_AVALANCHE,
            srcEid              : LZForwarder.ENDPOINT_ID_ETHEREUM,
            sourceAuthority     : Ethereum.SPARK_PROXY,
            executor            : executor,
            delegate            : address(1),
            owner               : address(1)
        });

        console.log("executor deployed at:", executor);
        console.log("receiver deployed at:", receiver);

        Deploy.setUpExecutorPermissions(executor, receiver, msg.sender);

        vm.stopBroadcast();
    }

}
