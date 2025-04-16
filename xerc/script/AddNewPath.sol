// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BasicXERC20Sample} from "@glacis/test/contracts/samples/token/BasicXERC20Sample.sol";
import {SimpleTokenMediator} from "@glacis/contracts/mediators/SimpleTokenMediator.sol";
import {GlacisCommons} from "@glacis/contracts/commons/GlacisCommons.sol";
import "forge-std/Script.sol";

/** GOALS OF THE DEMO

1. Deploy a new xERC20 token on 2 chains
2. Deploy 2 SimpleTokenMediator contracts on each chain
3. Set the xERC20 token to use the SimpleTokenMediators
4. Send through two GMP pathways, as configured within the SimpleTokenMediators

In documentation, explain why this is easier & how its done.
Explain how the SimpleTokenMediator contract can be edited to:
1. Have a preconfigured & set bridge, so that limits can be placed between the tokens
2. Have limit functionality be baked within it as well.

*/

contract AddNewPath is Script, GlacisCommons {
    address constant GLACIS_ROUTER_OPTIMISM = 0xb515a38AE7FAb6F85aD03cBBa227D8c198823180;
    address constant GLACIS_ROUTER_ARBITRUM = 0x46c2996ee4391787Afef520543c78f2C1aE3fE22;
    uint256 constant OPTIMISM_CHAIN_ID = 10;
    uint256 constant ARBITRUM_CHAIN_ID = 42161;

    uint256 constant AMOUNT_TO_SEND = 1 ether / 10;

    address constant XERC20_OPTIMISM = 0x0c2093c25932D0416C8943CBA70063Dc7461f99E;
    address constant XERC20_ARBITRUM = 0xE2e81C6a0ADd05Be1E3E65E09c307dC54F05a7cA;
    address constant GMP_ID = address(1); // Axelar

    function run() external {
        uint256[] memory chainIDs = new uint256[](1);
        bytes32[] memory counterparts = new bytes32[](1);

        uint256 optimismFork = vm.createSelectFork(vm.rpcUrl("optimism"));
        vm.startBroadcast(tx.origin);

        // First create a SimpleTokenMediators on Optimism
        SimpleTokenMediator opt_mediator = new SimpleTokenMediator(GLACIS_ROUTER_OPTIMISM, 1, tx.origin);

        // Set the mediators to mediate the token
        opt_mediator.setXERC20(XERC20_OPTIMISM);

        // Give the mediator the ability to mint tokens (100 per day, both ways)
        BasicXERC20Sample(XERC20_OPTIMISM).setLimits(address(opt_mediator), 100 ether, 100 ether);

        vm.stopBroadcast();

        // Do the same on Arbitrum
        vm.createSelectFork(vm.rpcUrl("arbitrum"));
        vm.startBroadcast(tx.origin);

        SimpleTokenMediator arb_mediator = new SimpleTokenMediator(GLACIS_ROUTER_ARBITRUM, 1, tx.origin);
        arb_mediator.setXERC20(XERC20_ARBITRUM);
        BasicXERC20Sample(XERC20_ARBITRUM).setLimits(address(arb_mediator), 100 ether, 100 ether);

        // On Arbitrum, set SimpleMediatorToken to accept requests from Optimism
        arb_mediator.addAllowedRoute(GlacisRoute(
            WILDCARD,
            bytes32(uint256(uint160(address(opt_mediator)))),
            GMP_ID
        ));
        chainIDs[0] = OPTIMISM_CHAIN_ID;
        counterparts[0] = bytes32(uint256(uint160(address(opt_mediator))));
        arb_mediator.addRemoteCounterparts(chainIDs, counterparts);


        vm.stopBroadcast();

        vm.selectFork(optimismFork);
        vm.startBroadcast(tx.origin);

        // On Optimism, set SimpleMediatorToken to accept requests from Arbitrum
        opt_mediator.addAllowedRoute(GlacisRoute(
            WILDCARD,
            bytes32(uint256(uint160(address(arb_mediator)))),
            GMP_ID
        ));
        chainIDs[0] = ARBITRUM_CHAIN_ID;
        counterparts[0] = bytes32(uint256(uint160(address(arb_mediator))));
        opt_mediator.addRemoteCounterparts(chainIDs, counterparts);


        // Now send a token from optimism to arbitrum
        BasicXERC20Sample(XERC20_OPTIMISM).approve(address(opt_mediator), AMOUNT_TO_SEND);
        address[] memory adapters = new address[](1);
        CrossChainGas[] memory fees = new CrossChainGas[](1);
        adapters[0] = GMP_ID;
        fees[0] = CrossChainGas(
            0,
            uint128(100_000_000_000_000)
        );
        opt_mediator.sendCrossChain{ value: 100_000_000_000_000  }(
            ARBITRUM_CHAIN_ID,
            bytes32(uint256(uint160(address(tx.origin)))),
            adapters,
            fees,
            tx.origin,
            AMOUNT_TO_SEND
        );

        vm.stopBroadcast();
    }
}
