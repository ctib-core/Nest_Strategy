// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title StrategyErrors - Contains all custom errors for Strategy contracts
/// @notice Centralized error definitions for better gas efficiency and consistency
abstract contract StrategyErrors {
    // ========== BaseStrategy Errors ==========
    
    /// @notice Thrown when an unsupported asset is used
    error BaseStrategy__Asset_Not_Supported();
    
    /// @notice Thrown when an arithmetic underflow would occur
    error BaseStrategy__Underflow();

    // ========== Cross-Protocol Strategy Errors ==========
    
    /// @notice Thrown when a request has already been processed (replay attack prevention)
    /// @param requestId The ID of the request that was already processed
    error Strategy__RequestAlreadyProcessed(bytes32 requestId);
    
    /// @notice Thrown when an unknown message type is received
    /// @param msgType The unknown message type that was received
    error Strategy__UnknownMessageType(uint16 msgType);
    
    /// @notice Thrown when a request contains invalid data
    error Strategy__InvalidRequest();
    
    /// @notice Thrown when there's insufficient gas to send a response
    error Strategy__InsufficientGasForResponse();

    // ========== Access Control Errors ==========
    
    /// @notice Thrown when a non-owner tries to call owner-only functions
    error Strategy__OnlyOwner();
    
    /// @notice Thrown when an invalid recipient address is provided
    error Strategy__InvalidRecipient();
    
    /// @notice Thrown when trying to withdraw more than the available balance
    error Strategy__InsufficientBalance();

    // ========== LayerZero Related Errors ==========
    
    /// @notice Thrown when LayerZero message sending fails
    error Strategy__MessageSendFailed();
    
    /// @notice Thrown when invalid endpoint ID is provided
    error Strategy__InvalidEndpointId();
    
    /// @notice Thrown when peer is not configured for the chain
    error Strategy__PeerNotConfigured(uint32 chainId);

    // ========== Execution Errors ==========
    
    /// @notice Thrown when deposit execution fails
    /// @param reason The reason for the failure
    error Strategy__DepositExecutionFailed(string reason);
    
    /// @notice Thrown when withdraw execution fails  
    /// @param reason The reason for the failure
    error Strategy__WithdrawExecutionFailed(string reason);
    
    /// @notice Thrown when state response sending fails
    error Strategy__StateResponseFailed();

    // ========== Validation Errors ==========
    
    /// @notice Thrown when zero amount is provided where non-zero is required
    error Strategy__ZeroAmount();
    
    /// @notice Thrown when zero address is provided where valid address is required
    error Strategy__ZeroAddress();
    
    /// @notice Thrown when deadline has passed
    error Strategy__DeadlineExpired();
    
    /// @notice Thrown when minimum amount requirements are not met
    error Strategy__MinimumAmountNotMet();

    // ========== Emergency/Pause Errors ==========
    
    /// @notice Thrown when contract is paused
    error Strategy__ContractPaused();
    
    /// @notice Thrown when emergency stop is activated
    error Strategy__EmergencyStop();
}