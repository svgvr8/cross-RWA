// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {XERC20Basic} from "@glacis/contracts/token/XERC20.sol";
import {SimpleTokenMediator} from "@glacis/contracts/mediators/SimpleTokenMediator.sol";
import "forge-std/Script.sol";

/** GOALS

1. Deploy a new xERC20 token
2. Deploy multiple SimpleTokenMediator contracts with different configurations
3. Set the xERC20 token to use the SimpleTokenMediator
4. Send through multiple pathways

In documentation, explain why this is easier & how its done.

*/

contract DeployXERC20 is Script {
    
}
