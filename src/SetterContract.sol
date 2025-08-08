// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ITeller } from "./Interface/ITellerContract.sol";
import { IBoring } from "./Interface/IBoringVault.sol";
import { IAccountant } from "./Interface/IAccountant.sol";
import{IPermissionManager} from "./Interface/IPermissionManager.sol";
import{ PermissionModifiers } from "./PermissionModifier.sol";

/**
 * @notice This contract implements the Nest Teller contract
 */
abstract contract SetterContract {
    using PermissionModifiers for *;

    address public NEST_TELLER_ADDRESS;
    address public BORING_VAULT_ADDRESS;
    address public PERMISSION_ADDRESS;
    address public ACCOUNT_ADDRESS;

    ITeller public TellerInterface;
    IBoring public BoringVault;
    IAccountant public Account;



    /**
     * @notice Only authorized personnel can update these addresses
     */
    function setTellerAddress(address _newTellerAddress, address _boringVault, address _accountant, address _permisionAddress) external onlyOwnerWithPermission(bytes4(keccak256("setTellerAddress(address,address,address,address)"))) {
        NEST_TELLER_ADDRESS = _newTellerAddress;
        BORING_VAULT_ADDRESS = _boringVault;
        ACCOUNT_ADDRESS = _accountant;
        PERMISSION_ADDRESS = _permisionAddress;

        TellerInterface = ITeller(_newTellerAddress);
        BoringVault = IBoring(_boringVault);
        Account = IAccountant(_accountant);
    }

    /**
     * @notice Restrict to owner only
     */
    modifier onlyOwnerWithPermission(bytes4 _functionSelector) {
        require(IPermissionManager(PERMISSION_ADDRESS).hasPermissions(msg.sender, _functionSelector), "Unauthorized");
        _;
    }
}
