// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BasicXERC20Sample} from "@glacis/test/contracts/samples/token/BasicXERC20Sample.sol";
import {SimpleTokenMediator} from "@glacis/contracts/mediators/SimpleTokenMediator.sol";
import {GlacisCommons} from "@glacis/contracts/commons/GlacisCommons.sol";
import "forge-std/Script.sol";

contract SendToken is Script, GlacisCommons {
    string constant CHAIN_TO_RUN_ON = "arbitrum";
    address constant GMP_CHAIN_ID = address(3);
    uint256 constant DEST_CHAIN_ID = 10;
    address constant XERC20 = 0x75B6AAEaF6DB9F2F5DFF09bc5ca6954c34Bd9fea;
    address constant SIMPLE_TOKEN_MEDIATOR = 0xC23436e54fEBF9cFdD5FDaD41142Ac7B706b8684;
    uint256 constant AMOUNT_TO_SEND = 100000;

    uint256 constant CROSS_CHAIN_GAS = 550_000_000_000_000;

    // string constant CHAIN_TO_RUN_ON = "optimism";
    // address constant GMP_CHAIN_ID = address(3);
    // uint256 constant DEST_CHAIN_ID = 42161;
    // address constant XERC20 = 0x75B6AAEaF6DB9F2F5DFF09bc5ca6954c34Bd9fea;
    // address constant SIMPLE_TOKEN_MEDIATOR = 0xa54B373A9e8305604F66836396073eE24ab09322;

    function run() external {
        vm.createSelectFork(CHAIN_TO_RUN_ON);
        vm.startBroadcast(tx.origin);

        // Now send a token from arbitrum to optimism
        BasicXERC20Sample(XERC20).approve(SIMPLE_TOKEN_MEDIATOR, AMOUNT_TO_SEND);
        address[] memory adapters = new address[](1);
        adapters[0] = GMP_CHAIN_ID;
        CrossChainGas[] memory fees = new CrossChainGas[](1);
        fees[0] = CrossChainGas(
            0,
            uint128(CROSS_CHAIN_GAS)
        );
        SimpleTokenMediator(SIMPLE_TOKEN_MEDIATOR).sendCrossChain{ value: CROSS_CHAIN_GAS  }(
            DEST_CHAIN_ID,
            bytes32(uint256(uint160(address(tx.origin)))),
            adapters,
            fees,
            tx.origin,
            AMOUNT_TO_SEND
        );

        vm.stopBroadcast();
    }

    IWormholeRelayer constant WORMHOLE_RELAYER = IWormholeRelayer(0x27428DD2d3DD32A4D7f7C497eAaa23130d894911);

    function _calculateCrossChainGasPrice(uint256 gas, uint256 dstChain, address gmp) internal view returns (uint256) {
        

        // For wormhole
        if (gmp == address(3)) {
            WORMHOLE_RELAYER.quoteEVMDeliveryPrice(
                101, // TODO: map chain ID to Wormhole chain ID
                0,
                gas
            );
        }
        // For layerzero (TODO)
        return 200_000_000_000_000;
    }
}