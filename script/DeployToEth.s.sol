// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {Strategy} from "../src/Stategy.sol";
import {StrategyFactory} from "../src/StategyFactory.sol";
import {PermissionManager} from "../src/PermissionManager.sol";
import {IPermissionManager} from "../src/Interface/IPermissionManager.sol";

contract DeployToETH is Script {
    Strategy public strategy;
    StrategyFactory public factory;
    PermissionManager public permission;

    address public deployer; 

    address public TELLER_ADDRESS = 0xc9F6a492Fb1D623690Dc065BBcEd6DfB4a324A35;
    address public BORING_ADDRESS = 0x593cCcA4c4bf58b7526a4C164cEEf4003C6388db;
    address public ACCOUNT_ADDRESS = 0xe0CF451d6E373FF04e8eE3c50340F18AFa6421E1;
    address public ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address public INTERACTIONADDRESS = 0xf0830060f836B8d54bF02049E5905F619487989e;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);

        vm.createSelectFork(vm.rpcUrl("ethereum"));
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying contracts to ETH network...");
        console.log("Deployer address:", deployer);

        deploy(deployer);
        grantPermission(deployer);
        setupConfig();

        vm.stopBroadcast();
           logAddress();
    }

    function deploy(address _deployer) internal {
        permission = new PermissionManager();
        strategy = new Strategy(ENDPOINT, _deployer);
        factory = new StrategyFactory(ENDPOINT, _deployer, address( permission));
    }

    function setupConfig() internal {
        strategy.setTellerAddress(TELLER_ADDRESS, BORING_ADDRESS, address( permission), ACCOUNT_ADDRESS);
    }

    function grantPermission(address _deployer) internal {
        bytes4[] memory permissions = new bytes4[](2);

        permissions[0] = factory.createNewStrategy.selector; 
        permissions[1] = strategy.withdrawNative.selector;  
        permissions[2] = strategy.setTellerAddress.selector; 

        IPermissionManager(permission).grantBatchPermission(_deployer, permissions);
        IPermissionManager(permission).grantBatchPermission(INTERACTIONADDRESS, permissions);
    }

    
    function logAddress() internal {
        console.log("PERMISSOONMANAGER ADDRESS WAS DEPLOYED AT", address(permission));
        console.log("STRATEGY ADDRESS WAS DEPLOYED AT", address(strategy));
        console.log("FACTORY ADDRESS WAS DEPLOYED", address(factory) );
    }
}
