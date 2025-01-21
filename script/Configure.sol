// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BasicXERC20Sample} from "@glacis/test/contracts/samples/token/BasicXERC20Sample.sol";
import {SimpleTokenMediator} from "@glacis/contracts/mediators/SimpleTokenMediator.sol";
import {GlacisCommons} from "@glacis/contracts/commons/GlacisCommons.sol";
import "forge-std/Script.sol";

contract Configure is Script, GlacisCommons {
    address constant CURRENT = 0x9C3adB01867085B5EABD061B9da69c087B589917;  // arbitrum
    address constant COUNTERPART = 0x861d69176daFd28fC141D799bF1Df17aF9C1316d;  // optimism
    uint256 constant DEST_CHAIN_ID = 11155420;  // Optimism Testnet
    // uint256 constant DEST_CHAIN_ID = 421614;    // Arbitrum Testnet

    function run() external {
        uint256[] memory chainIDs = new uint256[](1);
        bytes32[] memory counterparts = new bytes32[](1);

        vm.startBroadcast(tx.origin);

        // Set SimpleMediatorToken reserved for Wormhole to accept requests from Arbitrum
        SimpleTokenMediator(CURRENT).addAllowedRoute(GlacisRoute(
            WILDCARD,
            bytes32(uint256(uint160(COUNTERPART))),
            address(2) // ID 2 = LayerZero
        ));
        chainIDs[0] = DEST_CHAIN_ID;
        counterparts[0] = bytes32(uint256(uint160(COUNTERPART)));
        SimpleTokenMediator(CURRENT).addRemoteCounterparts(chainIDs, counterparts);

        vm.stopBroadcast();
    }
}
