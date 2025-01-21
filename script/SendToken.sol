// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BasicXERC20Sample} from "@glacis/test/contracts/samples/token/BasicXERC20Sample.sol";
import {SimpleTokenMediator} from "@glacis/contracts/mediators/SimpleTokenMediator.sol";
import {GlacisCommons} from "@glacis/contracts/commons/GlacisCommons.sol";
import "forge-std/Script.sol";

contract SendToken is Script, GlacisCommons {
    address constant XERC20 = 0x5f40dF87488DD1e3EBAf21eE90e1e959854440e1;
    address constant SIMPLE_TOKEN_MEDIATOR = 0xeA1BC1a5d8F10410a3f49979BC470Ae35320CA63;
    uint256 constant DEST_CHAIN_ID = 10;
    address constant GMP_CHAIN_ID = address(3);

    function run() external {
        vm.createSelectFork("arbitrum");
        vm.startBroadcast(tx.origin);

        // Now send a token from arbitrum to optimism
        BasicXERC20Sample(XERC20).approve(SIMPLE_TOKEN_MEDIATOR, 1 ether / 10);
        address[] memory adapters = new address[](1);
        adapters[0] = GMP_CHAIN_ID;
        CrossChainGas[] memory fees = new CrossChainGas[](1);
        fees[0] = CrossChainGas(
            0,
            uint128(100_000_000_000_000)
        );
        SimpleTokenMediator(SIMPLE_TOKEN_MEDIATOR).sendCrossChain{ value: 100_000_000_000_000  }(
            DEST_CHAIN_ID,
            bytes32(uint256(uint160(address(tx.origin)))),
            adapters,
            fees,
            tx.origin,
            1 ether / 10
        );

        vm.stopBroadcast();
    }
}
