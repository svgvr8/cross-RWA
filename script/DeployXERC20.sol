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

    // Optimism Testnet
    // address constant GLACIS_ROUTER = 0xefc27DdE9474468ED81054391c03560a2A217b87;

    // Arbitrum Testnet
    address constant GLACIS_ROUTER = 0x51f4510b1488d03A4c8C699fEa3c0B745a042e45;

    function run() external {
        vm.startBroadcast(tx.origin);

        // Deploy a new XERC20
        BasicXERC20Sample opt_xerc20 = new BasicXERC20Sample(tx.origin);

        // Then create some SimpleTokenMediators, which are token bridges powered by Glacis
        SimpleTokenMediator opt_mediator_wh = new SimpleTokenMediator(GLACIS_ROUTER, 1, tx.origin);
        SimpleTokenMediator opt_mediator_lz = new SimpleTokenMediator(GLACIS_ROUTER, 1, tx.origin);

        // Give the mediator the ability to mint tokens (100 per day, both ways)
        opt_xerc20.setLimits(address(opt_mediator_wh), 100 ether, 100 ether);
        opt_xerc20.setLimits(address(opt_mediator_lz), 100 ether, 100 ether);
        opt_mediator_wh.setXERC20(address(opt_xerc20));
        opt_mediator_lz.setXERC20(address(opt_xerc20));

        vm.stopBroadcast();
    }
}