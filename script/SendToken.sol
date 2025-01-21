// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BasicXERC20Sample} from "@glacis/test/contracts/samples/token/BasicXERC20Sample.sol";
import {SimpleTokenMediator} from "@glacis/contracts/mediators/SimpleTokenMediator.sol";
import {GlacisCommons} from "@glacis/contracts/commons/GlacisCommons.sol";
import "forge-std/Script.sol";

contract SendToken is Script, GlacisCommons {
    address constant XERC20 = 0x8c60C48B3Dde67Ed7c545E046c8ce5E53De30828;
    address constant SIMPLE_TOKEN_MEDIATOR = 0x9C3adB01867085B5EABD061B9da69c087B589917;
    uint256 constant DEST_CHAIN_ID = 11155420;
    address constant GMP_CHAIN_ID = address(2);

    function run() external {
        vm.startBroadcast(tx.origin);

        // Now send a token from arbitrum to optimism
        BasicXERC20Sample(XERC20).approve(address(SIMPLE_TOKEN_MEDIATOR), 1 ether);
        address[] memory adapters = new address[](1);
        adapters[0] = GMP_CHAIN_ID;
        CrossChainGas[] memory fees = new CrossChainGas[](1);
        fees[0] = CrossChainGas(
            0,
            uint128(80_000_000_000_000_000)
        );
        SimpleTokenMediator(SIMPLE_TOKEN_MEDIATOR).sendCrossChain{ value: 80_000_000_000_000_000  }(
            DEST_CHAIN_ID,
            bytes32(uint256(uint160(address(tx.origin)))),
            adapters,
            fees,
            tx.origin,
            1 ether
        );

        vm.stopBroadcast();
    }
}
