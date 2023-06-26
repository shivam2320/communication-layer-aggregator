//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import "./ILayerZeroEndpoint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../CommLayerAggregator/ICommLayer.sol";

contract LayerZeroImpl is ICommLayer, Ownable {
    /// @notice LayerZero endoint address
    ILayerZeroEndpoint public endpoint;

    /// @notice Communication Layers Aggregator address
    ICommLayer public commLayerAggregator;

    /// @notice mapping to keep track of failed messages
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
        public failedMessages;

    /// @notice Extra LayerZero fees customization parameters
    struct lzAdapterParams {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    event msgSent(
        uint16 _dstChainId,
        bytes _destination,
        bytes _payload,
        uint256 nonce
    );
    event RetriedPayload(uint16 _srcChainId, bytes _srcAddress, bytes _payload);
    event ForceResumed(uint16 _srcChainId, bytes _srcAddress, bytes _payload);

    /// @dev Initializes the contract by setting LayerZeroEndpoint and CommLayerAggregator address
    constructor(address _endpoint, address _commLayerAggregator) {
        endpoint = ILayerZeroEndpoint(_endpoint);
        commLayerAggregator = ICommLayer(_commLayerAggregator);
    }

    /// @notice This function is responsible to estimate fees required for sending message
    /// @param _dstChainId Destination Chain Id
    /// @param _userApplication Destination contract address
    /// @param _payload Encoded data to send on destination chain
    /// @param _adapterParameters Extra fees customization parameters
    /// @return nativeFee Fees required in native token
    /// @return zroFee Fees required in zro token
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bytes calldata _adapterParameters
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        return
            endpoint.estimateFees(
                _dstChainId,
                _userApplication,
                _payload,
                false,
                _adapterParameters
            );
    }

    /// @notice This function is responsible for setting source LayerZeroImpl addresses
    /// @dev onlyOwner is allowed to call this function
    /// @param _endpoint Source chain LayerZeroImpl address
    function changeEndpoint(address _endpoint) external onlyOwner {
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    /// @notice This function is responsible for chaning communication layer aggregator address
    /// @dev onlyOwner is allowed to call this function
    /// @param _aggregator Communication layer aggregator address
    function changeCommLayerAggregator(address _aggregator) external onlyOwner {
        commLayerAggregator = ICommLayer(_aggregator);
    }

    /// @notice This function is responsible for sending messages to another chain using LayerZero
    /// @dev It makes call to LayerZero endpoint contract
    /// @dev This function can only be called from CommLayerAggregator
    /// @param _destination Address of destination contract to send message on
    /// @param _payload Encoded data to send on destination chain
    /// @param extraParams Encoded extra parameters
    function sendMsg(
        address _destination,
        bytes calldata _payload,
        bytes memory extraParams
    ) public payable {
        (uint16 _dstChainId, address refundAd, bytes memory adapterParams) = abi
            .decode(extraParams, (uint16, address, bytes));

        uint64 nextNonce = endpoint.getOutboundNonce(
            _dstChainId,
            address(this)
        ) + 1;

        endpoint.send{value: msg.value}(
            _dstChainId,
            abi.encodePacked(_destination, address(this)),
            _payload,
            payable(refundAd),
            address(0x0),
            adapterParams
        );
        emit msgSent(
            _dstChainId,
            abi.encodePacked(_destination),
            _payload,
            nextNonce
        );
    }

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external onlyOwner {
        endpoint.setSendVersion(_version);
    }

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external onlyOwner {
        endpoint.setReceiveVersion(_version);
    }
}
