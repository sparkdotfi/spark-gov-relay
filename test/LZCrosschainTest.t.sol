// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import './CrosschainTestBase.sol';

import { LZBridgeTesting } from 'lib/xchain-helpers/src/testing/bridges/LZBridgeTesting.sol';
import { LZForwarder }     from 'lib/xchain-helpers/src/forwarders/LZForwarder.sol';
import { LZReceiver }      from 'lib/xchain-helpers/src/receivers/LZReceiver.sol';

import { LZCrosschainPayload } from './payloads/LZCrosschainPayload.sol';

contract LZCrosschainTest is CrosschainTestBase {

    using DomainHelpers   for *;
    using LZBridgeTesting for *;

    function deployCrosschainPayload(IPayload targetPayload, address bridgeReceiver)
        internal override returns (IPayload)
    {
        return IPayload(new LZCrosschainPayload(
            LZForwarder.ENDPOINT_ID_AVALANCHE,
            LZForwarder.ENDPOINT_ETHEREUM,
            bridgeReceiver,
            targetPayload,
            bridgeReceiver
        ));
    }

    function setupDomain() internal override {
        remote = getChain('avalanche').createFork();
        bridge = LZBridgeTesting.createLZBridge(
            mainnet,
            remote
        );

        remote.selectFork();
        bridgeReceiver = address(new LZReceiver({
            _destinationEndpoint : LZForwarder.ENDPOINT_AVALANCHE,
            _srcEid              : LZForwarder.ENDPOINT_ID_ETHEREUM,
            _sourceAuthority     : bytes32(uint256(uint160(defaultL2BridgeExecutorArgs.ethereumGovernanceExecutor))),
            _target              : vm.computeCreateAddress(address(this), 3),
            _delegate            : address(1),
            _owner               : address(1)
        }));

        mainnet.selectFork();
        vm.deal(L1_SPARK_PROXY, 0.01 ether);
    }

    function relayMessagesAcrossBridge() internal override {
        bridge.relayMessagesToDestination(true, defaultL2BridgeExecutorArgs.ethereumGovernanceExecutor, bridgeReceiver);
    }

}
