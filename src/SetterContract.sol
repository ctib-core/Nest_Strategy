// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ITeller } from "./Interface/ITellerContract.sol";
import { IBoring } from "./Interface/IBoringVault.sol";
import { IAccountant } from "./Interface/IAccountant.sol";

/**
 * @notice This contract implements the Nest Teller contract
 */
abstract contract SetterContract {
    address public NEST_TELLER_ADDRESS;
    address public BORING_VAULT_ADDRESS;
    address public ACCOUNT_ADDRESS;

    ITeller public TellerInterface;
    IBoring public BoringVault;
    IAccountant public Account;

    address public owner;

    constructor() {
        owner = msg.sender;

        // Set default values (optional)
        NEST_TELLER_ADDRESS = 0xc9F6a492Fb1D623690Dc065BBcEd6DfB4a324A35;
        BORING_VAULT_ADDRESS = 0x593cCcA4c4bf58b7526a4C164cEEf4003C6388db;
        ACCOUNT_ADDRESS = 0xe0CF451d6E373FF04e8eE3c50340F18AFa6421E1;

        TellerInterface = ITeller(NEST_TELLER_ADDRESS);
        BoringVault = IBoring(BORING_VAULT_ADDRESS);
        Account = IAccountant(ACCOUNT_ADDRESS);
    }

    /**
     * @notice Only authorized personnel can update these addresses
     */
    function setTellerAddress(address _newTellerAddress, address _boringVault, address _accountant) external onlyOwner {
        NEST_TELLER_ADDRESS = _newTellerAddress;
        BORING_VAULT_ADDRESS = _boringVault;
        ACCOUNT_ADDRESS = _accountant;

        TellerInterface = ITeller(_newTellerAddress);
        BoringVault = IBoring(_boringVault);
        Account = IAccountant(_accountant);
    }

    /**
     * @notice Restrict to owner only
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
}
