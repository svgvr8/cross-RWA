// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BasicXERC20Sample} from "@glacis/test/contracts/samples/token/BasicXERC20Sample.sol";
import {SimpleTokenMediator} from "@glacis/contracts/mediators/SimpleTokenMediator.sol";
import {GlacisCommons} from "@glacis/contracts/commons/GlacisCommons.sol";
import {IWormholeRelayer} from "@glacis/contracts/adapters/Wormhole/IWormholeRelayer.sol";
import "forge-std/Script.sol";

contract SendToken is Script, GlacisCommons {
    string constant CHAIN_TO_RUN_ON = "arbitrum";
    address constant GMP_CHAIN_ID = address(5);
    uint256 constant DEST_CHAIN_ID = 10;
    address constant XERC20 = 0x75B6AAEaF6DB9F2F5DFF09bc5ca6954c34Bd9fea;
    address constant SIMPLE_TOKEN_MEDIATOR =
        0xC23436e54fEBF9cFdD5FDaD41142Ac7B706b8684;

    // string constant CHAIN_TO_RUN_ON = "optimism";
    // address constant GMP_CHAIN_ID = address(5);
    // uint256 constant DEST_CHAIN_ID = 42161;
    // address constant XERC20 = 0x75B6AAEaF6DB9F2F5DFF09bc5ca6954c34Bd9fea;
    // address constant SIMPLE_TOKEN_MEDIATOR = 0xa54B373A9e8305604F66836396073eE24ab09322;

    // You can find destination gas by sending a transaction to a destination chain and checking the gas used.
    // In this example, we are overestimating the gas used for safety, simplicity, & discrepencies between chains.
    // https://optimistic.etherscan.io/tx/0x7176aa57d336ba1f97e61944ae96bf954a7329e2ff2d0596aa39e1f3eb14af11
    uint256 constant DESTINATION_CHAIN_GAS = 280000;
    uint256 constant AMOUNT_TO_SEND = 100;

    function run() external {
        vm.createSelectFork(CHAIN_TO_RUN_ON);
        vm.startBroadcast(tx.origin);

        // Approve the SimpleTokenMediator with the token to be sent
        BasicXERC20Sample(XERC20).approve(
            SIMPLE_TOKEN_MEDIATOR,
            AMOUNT_TO_SEND
        );

        // Calculate cross-chain gas
        uint128 gasCost = _calculateCrossChainGasPrice(
            DESTINATION_CHAIN_GAS,
            DEST_CHAIN_ID,
            GMP_CHAIN_ID
        );
        CrossChainGas[] memory fees = new CrossChainGas[](1);
        fees[0] = CrossChainGas(uint128(DESTINATION_CHAIN_GAS), gasCost);

        // Set the adapter (bridge) to be used
        address[] memory adapters = new address[](1);
        adapters[0] = GMP_CHAIN_ID;

        // Use the simple token mediator to send across chains
        SimpleTokenMediator(SIMPLE_TOKEN_MEDIATOR).sendCrossChain{
            value: gasCost
        }(
            DEST_CHAIN_ID,
            bytes32(uint256(uint160(address(tx.origin)))),
            adapters,
            fees,
            tx.origin,
            AMOUNT_TO_SEND
        );

        vm.stopBroadcast();
    }

    IWormholeRelayer constant WORMHOLE_RELAYER =
        IWormholeRelayer(0x27428DD2d3DD32A4D7f7C497eAaa23130d894911);
    // ILayerZeroEndpoint constant LAYERZERO_ENDPOINT = 
    //     ILayerZeroEndpoint(0x1a44076050125825900e736c501f859c50fE728c);

    function _calculateCrossChainGasPrice(
        uint256 gas,
        uint256 dstChain,
        address gmp
    ) internal view returns (uint128) {
        // For wormhole
        if (gmp == address(3)) {
            (uint256 nativePriceQuote, ) = WORMHOLE_RELAYER.quoteEVMDeliveryPrice(
                // Arbitrum Wormhole ChainID is 23. Optimism Wormhole ChainID is 24.
                // In a real application, a much larger mapping would be available & easier to access.
                dstChain == 42161 ? 23 : 24,
                0,
                gas
            );
            return uint128(nativePriceQuote);
        }
        // For others, we can guess-timate for the sake of the demo
        return 200_000_000_000_000;
    }
}