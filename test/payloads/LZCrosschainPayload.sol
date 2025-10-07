// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { OptionsBuilder } from "layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import { LZForwarder, ILayerZeroEndpointV2 } from 'lib/xchain-helpers/src/forwarders/LZForwarder.sol';

import { CrosschainPayload, IPayload } from './CrosschainPayload.sol';

contract LZCrosschainPayload is CrosschainPayload {

    using OptionsBuilder for bytes;

    address public immutable lzEndpoint;
    address public immutable receiver;

    uint32 public immutable dstEid;

    constructor(
        uint32   _dstEid,
        address  _lzEndpoint,
        address  _receiver,
        IPayload _targetPayload,
        address  _bridgeReceiver
    ) CrosschainPayload(_targetPayload, _bridgeReceiver) {
        dstEid     = _dstEid;
        lzEndpoint = _lzEndpoint;
        receiver   = _receiver;
    }

    function execute() external override {
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0);

        LZForwarder.sendMessage({
            _dstEid        : dstEid,
            _receiver      : bytes32(uint256(uint160(receiver))),
            endpoint       : ILayerZeroEndpointV2(lzEndpoint),
            _message       : encodeCrosschainExecutionMessage(),
            _options       : options,
            _refundAddress : msg.sender,
            _payInLzToken  : false
        });
    }

}
