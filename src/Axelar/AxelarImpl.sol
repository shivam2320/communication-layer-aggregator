//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IAxelarGateway} from "./IAxelarGateway.sol";
import {IAxelarGasService} from "./IAxelarGasService.sol";
import {IAxelarExecutable} from "./IAxelarExecutable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../CommLayerAggregator/ICommLayer.sol";

contract AxelarImpl is IAxelarExecutable, Ownable, ICommLayer {
    /// @notice Axelar gas service address
    IAxelarGasService public gasReceiver;

    /// @notice Communication layer aggregator addresses
    ICommLayer public commLayerAggregator;

    event msgSent(string _dstChain, address _destination, bytes _payload);

    event Executed(string sourceChain, string sourceAddress, bytes _payload);

    /// @dev Initializes the contract by setting gateway, gasReceiver and commLayerAggregator address
    constructor(
        address _gateway,
        address _gasReceiver,
        address _commLayerAggregator
    ) IAxelarExecutable(_gateway) {
        gasReceiver = IAxelarGasService(_gasReceiver);
        commLayerAggregator = ICommLayer(_commLayerAggregator);
    }

    /// @notice This function is responsible for changing commLayerAggregator address
    /// @dev onlyOwner can call this function
    /// @param _aggregator New communication layer aggregator address
    function changeCommLayerAggregator(address _aggregator) external onlyOwner {
        commLayerAggregator = ICommLayer(_aggregator);
    }

    /// @notice This function is responsible for changing gasReceiver address
    /// @dev onlyOwner can call this function
    /// @param _gasReceiver New gas receiver address
    function changeGasReceiver(address _gasReceiver) external onlyOwner {
        gasReceiver = IAxelarGasService(_gasReceiver);
    }

    /// @notice This function is responsible for sending messages to another chain using LayerZero
    /// @dev It makes call to LayerZero endpoint contract
    /// @dev This function can only be called from CommLayerAggregator
    /// @param destinationAddress Address of destination contract to send message on
    /// @param payload Encoded data to send on destination chain
    /// @param extraParams Encoded extra parameters
    function sendMsg(
        address destinationAddress,
        bytes memory payload,
        bytes memory extraParams
    ) external payable {
        string memory destinationChain = abi.decode(extraParams, (string));
        if (msg.value > 0) {
            gasReceiver.payNativeGasForContractCall{value: msg.value}(
                address(this),
                destinationChain,
                toAsciiString(destinationAddress),
                payload,
                msg.sender
            );
        }
        gateway.callContract(
            destinationChain,
            toAsciiString(destinationAddress),
            payload
        );
        emit msgSent(destinationChain, destinationAddress, payload);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(
                uint8(uint256(uint160(x)) / (2 ** (8 * (19 - i))))
            );
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
