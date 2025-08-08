// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Contains all events for BaseStrategy
abstract contract StrategyEvents {
    /// @notice Emitted when deposit via Teller is successful
    event TellerDeposit(address indexed user, address indexed asset, uint256 amount, uint256 sharesMinted);

    /// @notice Emitted when teller shares are updated
    event TellerSharesUpdated(uint256 newShareBalance);

    /// @notice Emitted when vault value is updated
    event VaultValueUpdated(uint256 newVaultValue);

    /// @notice Emitted when teller allocation is updated
    event TellerAllocationUpdated(uint256 newTellerAllocation);

 /// @notice Emitted when teller share is updated by  withdraw
    event TellerShareReduced(uint256 oldShare, uint256 newshare);

 ///@notice Emitted when teller withdraw happens
    event  WithdrawComplete(int256 shareAmount, uint256 assetOut,uint256 minimumAssets, address to);

///@notice Emitted when profit is made
    event ProfitMade(uint256 totalValueInVault, uint256 amountAllocated, int256 yield);

///@notice Emitted when loss is made
    event LossMade(uint256 totalValueInVault, uint256 amountAllocated, int256 yield);

    // ========== Cross-Protocol Events ==========
    
    /// @notice Emitted when a cross-protocol deposit request is received
    event CrossProtocolDepositReceived(bytes32 indexed requestId, address indexed requester, address asset, uint256 amount);
    
    /// @notice Emitted when a cross-protocol withdraw request is received
    event CrossProtocolWithdrawReceived(bytes32 indexed requestId, address indexed requester, address asset, uint256 shares);
    
    /// @notice Emitted when a state response is sent back to requesting chain
    event StateResponseSent(bytes32 indexed requestId, uint32 indexed dstEid, bool success, uint256 resultAmount);
    
    /// @notice Emitted when a state response is received from another chain
    event StateResponseReceived(bytes32 indexed requestId, bool success, uint256 resultAmount, string errorMessage);
    
    /// @notice Emitted when any cross-protocol request is processed
    event RequestProcessed(bytes32 indexed requestId, uint16 msgType, bool success);
    
    /// @notice Emitted when state response sending fails
    event StateResponseFailed(bytes32 indexed requestId, uint32 indexed dstEid, string reason);
    
    /// @notice Emitted when contract is funded with native tokens for gas
    event ContractFunded(address indexed funder, uint256 amount, uint256 newBalance);
    
    /// @notice Emitted when minimum gas balance requirement is updated
    event MinimumGasBalanceUpdated(uint256 newMinimumBalance);

    // ========== Updated Events (fixing inconsistent names) ==========
    
    /// @notice Emitted when teller shares are changed (replaces TellerSharesUpdated and TellerShareReduced)
    event TellerSharesChanged(uint256 oldShares, uint256 newShares);
    
    /// @notice Emitted when vault value is changed (replaces VaultValueUpdated)
    event VaultValueChanged(uint256 oldValue, uint256 newValue);
    
    /// @notice Emitted when teller allocation is changed (replaces TellerAllocationUpdated)
    event TellerAllocationChanged(uint256 oldAllocation, uint256 newAllocation);
}
