// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BasicXERC20Sample} from "@glacis/test/contracts/samples/token/BasicXERC20Sample.sol";
import {SimpleTokenMediator} from "@glacis/contracts/mediators/SimpleTokenMediator.sol";
import {GlacisCommons} from "@glacis/contracts/commons/GlacisCommons.sol";
import "forge-std/Script.sol";

/** GOALS

1. Deploy a new xERC20 token
2. Deploy SimpleTokenMediator contract
3. Set the xERC20 token to use the SimpleTokenMediator
4. Send through multiple pathways

In documentation, explain why this is easier & how its done.
Explain how the SimpleTokenMediator contract can be edited to:
1. Have a preconfigured & set bridge, so that limits can be placed between the tokens
2. Have limit functionality be baked within it as well.

*/

contract DeployXERC20 is Script, GlacisCommons {
    address constant GLACIS_ROUTER_OPTIMISM = 0xefc27DdE9474468ED81054391c03560a2A217b87;
    address constant GLACIS_ROUTER_ARBITRUM = 0x51f4510b1488d03A4c8C699fEa3c0B745a042e45;
    uint256 constant OPTIMISM_TESTNET_CHAIN_ID = 11155420;
    uint256 constant ARBITRUM_TESTNET_CHAIN_ID = 421614;

    function run() external {
        uint256 optimismFork = vm.createSelectFork(vm.rpcUrl("optimism"));
        vm.startBroadcast(tx.origin);

        // Deploy a new XERC20
        BasicXERC20Sample opt_xerc20 = new BasicXERC20Sample(tx.origin);

        // Then create some SimpleTokenMediators, which are token bridges powered by Glacis
        SimpleTokenMediator opt_mediator_wh = new SimpleTokenMediator(GLACIS_ROUTER_OPTIMISM, 1, tx.origin);
        SimpleTokenMediator opt_mediator_lz = new SimpleTokenMediator(GLACIS_ROUTER_OPTIMISM, 1, tx.origin);

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

        arb_xerc20.setLimits(address(arb_mediator_wh), 100 ether, 100 ether);
        arb_xerc20.setLimits(address(arb_mediator_lz), 100 ether, 100 ether);

        vm.stopBroadcast();

        uint256[] memory chainIDs = new uint256[](1);
        bytes32[] memory counterparts = new bytes32[](1);

        vm.selectFork(optimismFork);
        vm.startBroadcast(tx.origin);

        // On Optimism, set SimpleMediatorToken reserved for Wormhole to accept requests from Arbitrum
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

        // Now send a token from arbitrum to optimism
        arb_xerc20.approve(address(arb_mediator_wh), 1 ether);
        address[] memory adapters = new address[](1);
        adapters[0] = address(2); // Wormhole
        CrossChainGas[] memory fees = new CrossChainGas[](1);
        fees[0] = CrossChainGas(
            0,
            uint128(80_000_000_000_000_000)
        );
        arb_mediator_lz.sendCrossChain{ value: 80_000_000_000_000_000  }(
            OPTIMISM_TESTNET_CHAIN_ID,
            bytes32(uint256(uint160(address(tx.origin)))),
            adapters,
            fees,
            tx.origin,
            1 ether
        );

        vm.stopBroadcast();
    }
}
