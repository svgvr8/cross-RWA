## XERC-20 Glacis Demo

Creates a new XERC-20 token that can be sent through both LZ & WH via Glacis.  


Deploys 2 contracts and sends tokens across two pathways from Arbitrum to Optimism:  

```
forge script script/SimulateDeployMultiXERC20.sol --broadcast --private-key $PRIVATE_KEY
```  

Sends a token from one chain to another (change the constants within the script first):  

```
forge script script/SendToken.sol --broadcast --private-key $PRIVATE_KEY
```  

Adds a new SimpleTokenMediator to the token:  

```
forge script script/AddNewPath.sol --broadcast --private-key $PRIVATE_KEY
```

## SimpleTokenMediator Deployment

If you just want to just deploy a SimpleTokenMediator, use this script:  

```
forge script script/JustDeployTokenMediator.sol --broadcast --private-key $PRIVATE_KEY
```
