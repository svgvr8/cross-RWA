// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BasicXERC20Sample} from "@glacis/test/contracts/samples/token/BasicXERC20Sample.sol";
import {SimpleTokenMediator} from "@glacis/contracts/mediators/SimpleTokenMediator.sol";
import {GlacisCommons} from "@glacis/contracts/commons/GlacisCommons.sol";
import "forge-std/Script.sol";

/// @notice Just deploys a SimpleTokenMediator on optimism and arbitrum, for a given XERC20.
contract SimulateDeployMultiXERC20 is Script, GlacisCommons {
    address constant GLACIS_ROUTER_OPTIMISM = 0xb515a38AE7FAb6F85aD03cBBa227D8c198823180;
    address constant GLACIS_ROUTER_ARBITRUM = 0x46c2996ee4391787Afef520543c78f2C1aE3fE22;
    address constant XERC20_ROUTER_OPTIMISM = address(0);
    address constant XERC20_ROUTER_ARBITRUM = address(0);
    uint256 constant OPTIMISM_TESTNET_CHAIN_ID = 10;
    uint256 constant ARBITRUM_TESTNET_CHAIN_ID = 42161;

    function run() external {
        uint256 optimismFork = vm.createSelectFork(vm.rpcUrl("optimism"));
        vm.startBroadcast(tx.origin);

        // Create a SimpleTokenMediator, which are token bridges powered by Glacis
        SimpleTokenMediator opt_mediator = new SimpleTokenMediator(GLACIS_ROUTER_OPTIMISM, 1, tx.origin);

        // Set the mediators to mediate the token
        // The mediator will not have the ability to mint tokens yet. It will have to be set by the token admin.
        opt_mediator.setXERC20(address(XERC20_ROUTER_OPTIMISM));

        vm.stopBroadcast();

        // Do the same on Arbitrum
        uint256 arbitrumFork = vm.createSelectFork(vm.rpcUrl("arbitrum"));
        vm.startBroadcast(tx.origin);

        SimpleTokenMediator arb_mediator = new SimpleTokenMediator(GLACIS_ROUTER_ARBITRUM, 1, tx.origin);
        arb_mediator.setXERC20(address(XERC20_ROUTER_ARBITRUM));

        vm.stopBroadcast();

        uint256[] memory chainIDs = new uint256[](1);
        bytes32[] memory counterparts = new bytes32[](1);

        vm.selectFork(optimismFork);
        vm.startBroadcast(tx.origin);

        // On Optimism, set SimpleMediatorToken reserved for Wormhole to accept requests from Arbitrum
        // A custom smart contract can be written to simplify configuration process, if desired
        opt_mediator.addAllowedRoute(GlacisRoute(
            WILDCARD, // Allow any chain
            bytes32(uint256(uint160(address(arb_mediator)))),
            address(WILDCARD) // Allow any bridge
        ));
        chainIDs[0] = ARBITRUM_TESTNET_CHAIN_ID;
        counterparts[0] = bytes32(uint256(uint160(address(arb_mediator))));
        opt_mediator.addRemoteCounterparts(chainIDs, counterparts);

        vm.stopBroadcast();

        vm.selectFork(arbitrumFork);
        vm.startBroadcast(tx.origin);

        // On Arbitrum, set SimpleMediatorToken reserved for Wormhole to accept requests from Arbitrum
        arb_mediator.addAllowedRoute(GlacisRoute(
            WILDCARD, // Allow any chain
            bytes32(uint256(uint160(address(opt_mediator)))),
            address(WILDCARD) // Allow any bridge
        ));
        chainIDs[0] = OPTIMISM_TESTNET_CHAIN_ID;
        counterparts[0] = bytes32(uint256(uint160(address(opt_mediator))));
        arb_mediator.addRemoteCounterparts(chainIDs, counterparts);

        // Cannot send the token right now, but

        vm.stopBroadcast();
    }
}
