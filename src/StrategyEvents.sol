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
}
