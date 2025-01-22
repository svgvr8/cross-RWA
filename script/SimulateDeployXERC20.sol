// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BasicXERC20Sample} from "@glacis/test/contracts/samples/token/BasicXERC20Sample.sol";
import {SimpleTokenMediator} from "@glacis/contracts/mediators/SimpleTokenMediator.sol";
import {GlacisCommons} from "@glacis/contracts/commons/GlacisCommons.sol";
import "forge-std/Script.sol";

/// @notice Deploys an XERC20 on Optimism & Arbitrum, gives them 2 SimpleTokenMediators with different
/// configurations and bridges through them.
contract SimulateDeployXERC20 is Script, GlacisCommons {
    address constant GLACIS_ROUTER_OPTIMISM = 0xb515a38AE7FAb6F85aD03cBBa227D8c198823180;
    address constant GLACIS_ROUTER_ARBITRUM = 0x46c2996ee4391787Afef520543c78f2C1aE3fE22;
    uint256 constant OPTIMISM_TESTNET_CHAIN_ID = 10;
    uint256 constant ARBITRUM_TESTNET_CHAIN_ID = 42161;

    uint256 constant AMOUNT_TO_SEND = 1 ether / 10;

    function run() external {
        uint256 optimismFork = vm.createSelectFork(vm.rpcUrl("optimism"));
        vm.startBroadcast(tx.origin);

        // Deploy a new XERC20
        BasicXERC20Sample opt_xerc20 = new BasicXERC20Sample(tx.origin);

        // Then create some SimpleTokenMediators, which are token bridges powered by Glacis
        SimpleTokenMediator opt_mediator_wh = new SimpleTokenMediator(GLACIS_ROUTER_OPTIMISM, 1, tx.origin);
        SimpleTokenMediator opt_mediator_lz = new SimpleTokenMediator(GLACIS_ROUTER_OPTIMISM, 1, tx.origin);

        // Set the mediators to mediate the token
        opt_mediator_wh.setXERC20(address(opt_xerc20));
        opt_mediator_lz.setXERC20(address(opt_xerc20));

        // Give the mediator the ability to mint tokens (100 per day, both ways)
        opt_xerc20.setLimits(address(opt_mediator_wh), 100 ether, 100 ether);
        opt_xerc20.setLimits(address(opt_mediator_lz), 100 ether, 100 ether);

        vm.stopBroadcast();

        // Do the same on Arbitrum
        uint256 arbitrumFork = vm.createSelectFork(vm.rpcUrl("arbitrum"));
        vm.startBroadcast(tx.origin);

        BasicXERC20Sample arb_xerc20 = new BasicXERC20Sample(tx.origin);
        SimpleTokenMediator arb_mediator_wh = new SimpleTokenMediator(GLACIS_ROUTER_ARBITRUM, 1, tx.origin);
        SimpleTokenMediator arb_mediator_lz = new SimpleTokenMediator(GLACIS_ROUTER_ARBITRUM, 1, tx.origin);

        arb_mediator_wh.setXERC20(address(arb_xerc20));
        arb_mediator_lz.setXERC20(address(arb_xerc20));

        arb_xerc20.setLimits(address(arb_mediator_wh), 100 ether, 100 ether);
        arb_xerc20.setLimits(address(arb_mediator_lz), 100 ether, 100 ether);

        vm.stopBroadcast();

        uint256[] memory chainIDs = new uint256[](1);
        bytes32[] memory counterparts = new bytes32[](1);

        vm.selectFork(optimismFork);
        vm.startBroadcast(tx.origin);

        // On Optimism, set SimpleMediatorToken reserved for Wormhole to accept requests from Arbitrum
        // A custom smart contract can be written to simplify configuration process, if desired
        opt_mediator_wh.addAllowedRoute(GlacisRoute(
            WILDCARD,
            bytes32(uint256(uint160(address(arb_mediator_wh)))),
            address(3) // ID 3 = Wormhole
        ));
        chainIDs[0] = ARBITRUM_TESTNET_CHAIN_ID;
        counterparts[0] = bytes32(uint256(uint160(address(arb_mediator_wh))));
        opt_mediator_wh.addRemoteCounterparts(chainIDs, counterparts);

        // On Optimism, set SimpleMediatorToken reserved for LayerZero to accept requests from Arbitrum
        opt_mediator_lz.addAllowedRoute(GlacisRoute(
            WILDCARD,
            bytes32(uint256(uint160(address(arb_mediator_lz)))),
            address(2)  // ID 2 = LayerZero
        ));
        chainIDs[0] = ARBITRUM_TESTNET_CHAIN_ID;
        counterparts[0] = bytes32(uint256(uint160(address(arb_mediator_lz))));
        opt_mediator_lz.addRemoteCounterparts(chainIDs, counterparts);

        vm.stopBroadcast();

        vm.selectFork(arbitrumFork);
        vm.startBroadcast(tx.origin);

        // On Arbitrum, set SimpleMediatorToken reserved for Wormhole to accept requests from Arbitrum
        arb_mediator_wh.addAllowedRoute(GlacisRoute(
            WILDCARD,
            bytes32(uint256(uint160(address(opt_mediator_wh)))),
            address(3) // ID 3 = Wormhole
        ));
        chainIDs[0] = OPTIMISM_TESTNET_CHAIN_ID;
        counterparts[0] = bytes32(uint256(uint160(address(opt_mediator_wh))));
        arb_mediator_wh.addRemoteCounterparts(chainIDs, counterparts);

        // On Optimism, set SimpleMediatorToken reserved for LayerZero to accept requests from Arbitrum
        arb_mediator_lz.addAllowedRoute(GlacisRoute(
            WILDCARD,
            bytes32(uint256(uint160(address(opt_mediator_lz)))),
            address(2)  // ID 2 = LayerZero
        ));
        chainIDs[0] = OPTIMISM_TESTNET_CHAIN_ID;
        counterparts[0] = bytes32(uint256(uint160(address(opt_mediator_lz))));
        arb_mediator_lz.addRemoteCounterparts(chainIDs, counterparts);

        // Now send a token from arbitrum to optimism via Wormhole
        arb_xerc20.approve(address(arb_mediator_wh), AMOUNT_TO_SEND);
        address[] memory adapters = new address[](1);
        CrossChainGas[] memory fees = new CrossChainGas[](1);
        adapters[0] = address(3); // WH
        fees[0] = CrossChainGas(
            0,
            uint128(100_000_000_000_000)
        );
        arb_mediator_wh.sendCrossChain{ value: 100_000_000_000_000  }(
            OPTIMISM_TESTNET_CHAIN_ID,
            bytes32(uint256(uint160(address(tx.origin)))),
            adapters,
            fees,
            tx.origin,
            AMOUNT_TO_SEND
        );

        // Also send a token from arbitrum to optimism via LayerZero
        arb_xerc20.approve(address(arb_mediator_lz), AMOUNT_TO_SEND);
        adapters[0] = address(2); // LZ
        arb_mediator_lz.sendCrossChain{ value: 100_000_000_000_000  }(
            OPTIMISM_TESTNET_CHAIN_ID,
            bytes32(uint256(uint160(address(tx.origin)))),
            adapters,
            fees,
            tx.origin,
            AMOUNT_TO_SEND
        );


        vm.stopBroadcast();
    }
}
