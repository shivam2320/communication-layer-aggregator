// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "../Wormhole/IWormholeRelayer.sol";
import "../CommLayerAggregator/ICommLayer.sol";

contract WormholeImpl is ICommLayer {
    /// @notice Communication Layers Aggregator address
    address public commLayerAggregator;

    /// @dev Wormhole Relayer address
    IWormholeRelayer public relayer =
        IWormholeRelayer(0x80aC94316391752A193C1c47E27D382b507c93F3);

    modifier onlyRelayerContract() {
        require(
            msg.sender == address(relayer),
            "msg.sender is not WormholeRelayer contract."
        );
        _;
    }

    function sendMsg(
        address destination,
        bytes calldata payload,
        bytes memory extraParams
    ) public payable {
        uint16 targetChain = abi.decode(extraParams, (uint16));
        uint256 gasLimit = 500000;
        uint256 receiverValue = 0; // don't deliver any 'msg.value' along with the message

        //calculate cost to deliver message
        (uint256 deliveryCost, ) = relayer.quoteEVMDeliveryPrice(
            targetChain,
            receiverValue,
            gasLimit
        );

        // publish delivery request
        relayer.sendPayloadToEvm{value: deliveryCost}(
            targetChain,
            destination,
            payload,
            receiverValue,
            gasLimit
        );
    }
}
