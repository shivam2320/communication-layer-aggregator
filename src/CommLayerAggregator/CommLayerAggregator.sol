//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ICommLayer.sol";

contract CommLayerAggregator is AccessControl {
    using Counters for Counters.Counter;

    /// @notice Counter to keep track of supported Communication Layers
    Counters.Counter private _commLayerIds;

    mapping(uint256 => address) public commLayerId;

    /// @notice This function is responsible for adding new communication layer to aggregator
    /// @dev onlyOwner is allowed to call this function
    /// @param _newCommLayer Address of new communication layer
    function setCommLayer(
        address _newCommLayer
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newCommLayer != address(0), "Cannot be a address(0)");
        _commLayerIds.increment();
        uint256 commId = _commLayerIds.current();
        commLayerId[commId] = _newCommLayer;
    }

    /// @notice This function returns address of communication layer corresponding to its id
    /// @param _id Id of the communication layer
    function getCommLayer(uint256 _id) external view returns (address) {
        return commLayerId[_id];
    }

    /// @notice This function is responsible for sending messages to another chain
    /// @dev It makes call to corresponding commLayer depending on commLayerId
    /// @param _id Id of communication layer
    /// @param _destinationAddress Address of destination contract to send message on
    /// @param _payload Address of destination contract to send message on
    /// @param _extraParams Encoded extra parameters
    function sendMsg(
        uint256 _id,
        address _destinationAddress,
        bytes calldata _payload,
        bytes calldata _extraParams
    ) public payable {
        ICommLayer(commLayerId[_id]).sendMsg{value: msg.value}(
            _destinationAddress,
            _payload,
            _extraParams
        );
    }

    /// @notice This function is responsible for bulk sending messages to another chain
    /// @dev It makes call to corresponding commLayer depending on commLayerId
    /// @param _id Id of communication layer
    /// @param _destinationAddress Address of destination contract to send message on
    /// @param _payload Address of destination contract to send message on
    /// @param _extraParams Encoded extra parameters
    function bulkSendMsg(
        uint256[] memory _id,
        address[] calldata _destinationAddress,
        bytes[] calldata _payload,
        bytes[] calldata _extraParams
    ) public payable {
        for (uint i; i < _id.length; ) {
            ICommLayer(commLayerId[_id[i]]).sendMsg{value: msg.value}(
                _destinationAddress[i],
                _payload[i],
                _extraParams[i]
            );
            unchecked {
                ++i;
            }
        }
    }
}
