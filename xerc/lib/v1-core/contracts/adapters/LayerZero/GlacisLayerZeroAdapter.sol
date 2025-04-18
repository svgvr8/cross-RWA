// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import {IGlacisRouter} from "../../interfaces/IGlacisRouter.sol";
import {GlacisAbstractAdapter} from "../GlacisAbstractAdapter.sol";
import {SimpleNonblockingLzApp} from "./SimpleNonblockingLzApp.sol";
import {GlacisAbstractAdapter__IDArraysMustBeSameLength, GlacisAbstractAdapter__DestinationChainIdNotValid, GlacisAbstractAdapter__ChainIsNotAvailable, GlacisAbstractAdapter__NoRemoteAdapterForChainId} from "../GlacisAbstractAdapter.sol";
import {AddressBytes32} from "../../libraries/AddressBytes32.sol";
import {GlacisCommons} from "../../commons/GlacisCommons.sol";

/// @title Glacis Adapter for Layer Zero
/// @notice A Glacis Adapter for the LayerZero V1. Sends messages through _lzSend() and receives
/// messages via _nonblockingLzReceive()
contract GlacisLayerZeroAdapter is
    SimpleNonblockingLzApp,
    GlacisAbstractAdapter
{
    using AddressBytes32 for bytes32;

    constructor(
        address _glacisRouter,
        address _lzEndpoint,
        address _owner
    )
        SimpleNonblockingLzApp(_lzEndpoint)
        GlacisAbstractAdapter(IGlacisRouter(_glacisRouter), _owner)
    {}

    mapping(uint256 => uint16) internal glacisChainIdToAdapterChainId;
    mapping(uint16 => uint256) public adapterChainIdToGlacisChainId;

    bytes public adapterParams = bytes("");

    event GlacisLayerZeroAdapter__SetGlacisChainIDs(uint256[] chainIDs, uint16[] lzIDs);

    /// @notice Sets the corresponding LayerZero chain ID for the specified Glacis chain ID
    /// @param chainIDs Glacis chain IDs
    /// @param lzIDs Layer Zero chain IDs
    function setGlacisChainIds(
        uint256[] calldata chainIDs,
        uint16[] calldata lzIDs
    ) external onlyOwner {
        uint256 glacisIDsLen = chainIDs.length;
        if (glacisIDsLen != lzIDs.length)
            revert GlacisAbstractAdapter__IDArraysMustBeSameLength();

        for (uint256 i; i < glacisIDsLen; ) {
            uint256 glacisID = chainIDs[i];
            uint16 lzID = lzIDs[i];

            if (glacisID == 0)
                revert GlacisAbstractAdapter__DestinationChainIdNotValid();

            glacisChainIdToAdapterChainId[glacisID] = lzID;
            adapterChainIdToGlacisChainId[lzID] = glacisID;

            unchecked {
                ++i;
            }
        }

        emit GlacisLayerZeroAdapter__SetGlacisChainIDs(chainIDs, lzIDs);
    }

    /// @notice Gets the corresponding LayerZero chain ID for the specified Glacis chain ID
    /// @param chainId Glacis chain ID
    /// @return The corresponding LayerZero chain Id as bytes32
    function adapterChainID(uint256 chainId) external view returns (uint16) {
        return glacisChainIdToAdapterChainId[chainId];
    }

    /// @notice Queries if the specified Glacis chain ID is supported by this adapter
    /// @param chainId Glacis chain ID
    /// @return True if chain is supported, false otherwise
    function chainIsAvailable(uint256 chainId) public view returns (bool) {
        return glacisChainIdToAdapterChainId[chainId] != 0;
    }

    /// @notice Dispatch payload to specified Glacis chain ID and address through LayerZero GMP
    /// @param toChainId Destination chain (Glacis ID)
    /// @param refundAddress The address to refund native asset surplus
    /// @param payload Payload to send
    function _sendMessage(
        uint256 toChainId,
        address refundAddress,
        GlacisCommons.CrossChainGas memory,
        bytes memory payload
    ) internal override {
        bytes32 remoteCounterpart = remoteCounterpart[toChainId];
        uint16 _dstchainId = glacisChainIdToAdapterChainId[toChainId];

        if (remoteCounterpart == bytes32(0))
            revert GlacisAbstractAdapter__NoRemoteAdapterForChainId(toChainId);
        if (_dstchainId == 0)
            revert GlacisAbstractAdapter__ChainIsNotAvailable(toChainId);
        _lzSend({
            _dstChainId: _dstchainId,
            _dstChainAddress: remoteCounterpart.toAddress(),
            _payload: payload,
            _refundAddress: payable(refundAddress),
            _zroPaymentAddress: address(0),
            _adapterParams: adapterParams,
            _nativeFee: msg.value
        });
    }

    /// @notice Receives route message from LayerZero and routes it to GlacisRouter
    /// @param srcChainId Source chain (LayerZero ID)
    /// @param sourceAddress Source address on remote chain
    /// @param payload Payload to route
    function _nonblockingLzReceive(
        uint16 srcChainId,
        bytes memory sourceAddress, // srcAddress, will be the other adapter
        uint64,
        bytes memory payload
    )
        internal
        override
        // Only supports EVMs
        onlyAuthorizedAdapter(
            adapterChainIdToGlacisChainId[srcChainId],
            bytes32(bytes20(sourceAddress)) >> 96
        )
    {
        GLACIS_ROUTER.receiveMessage(
            adapterChainIdToGlacisChainId[srcChainId],
            payload
        );
    }

    /// Sets the adapter parameters for LayerZero messages.
    /// @param params The desired adapter params.
    function setAdapterParams(bytes memory params) external onlyOwner {
        adapterParams = params;
    } 
}
