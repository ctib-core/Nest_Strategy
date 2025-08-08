// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import{IPermissionManager} from "./Interface/IPermissionManager.sol";

library PermissionModifiers {

// /** 
//  * @dev This library holds the modifier which is going to be used across the protocol to check if an address can call a function
//  * @notice _permissionManager contract address
//  * @notice function selector to check
//  * @author 0xodeili Lee
//  */
modifier onlyWithPermission(address _permissionManager, bytes4 functionSelector) {
    require(
        IPermissionManager(_permissionManager).hasPermissions(msg.sender, functionSelector),
        "PermissionModifier: not authorized"
    );
    _;
}

}
