// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import{BaseStrategy} from "./BaseStrategy.sol";
import{StrategyErrors} from "./StrategyErrors.sol";
import{ITeller} from "./Interface/ITellerContract.sol";
import{IBoring} from "./Interface/IBoringVault.sol";
import{IAccountant} from "./Interface/IAccountant.sol";

contract  Strategy is OApp, OAppOptionsType3, BaseStrategy {
    /// @notice Last string received from any remote chain
    string public lastMessage;

    /// @notice Message types for cross-protocol operations
    uint16 public constant SEND = 1;
    uint16 public constant DEPOSIT_REQUEST = 2;
    uint16 public constant WITHDRAW_REQUEST = 3;
    uint16 public constant STATE_RESPONSE = 4;

    /// @notice Struct for deposit request messages
    struct DepositRequest {
        address depositAsset;
        uint256 depositAmount;
        uint256 minimumMint;
        bool iswithpermit;
        PermitData permitData;
        address requester;
        bytes32 requestId;
    }

    /// @notice Struct for withdraw request messages
    struct WithdrawRequest {
        address withdrawAsset;
        uint256 shareAmount;
        uint256 minimumAssets;
        address to;
        address requester;
        bytes32 requestId;
    }

    /// @notice Struct for state response messages
    struct StateResponse {
        bytes32 requestId;
        bool success;
        uint256 resultAmount; // shares minted or assets withdrawn
        string errorMessage;
        uint256 timestamp;
    }

    /// @notice Mapping to track processed requests to prevent replay attacks
    mapping(bytes32 => bool) public processedRequests;



    /// @notice Initialization status to prevent double initialization
    bool private initialized;

    /// @notice Initialize with Endpoint V2 and owner address
    /// @param _endpoint The local chain's LayerZero Endpoint V2 address
    /// @param _owner    The address permitted to configure this OApp
    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

    /// @notice Initialize the cloned contract (for factory deployment)
    /// @param _endpoint The local chain's LayerZero Endpoint V2 address
    /// @param _owner The address permitted to configure this OApp
    /// @param _tellerAddress The Nest Teller contract address
    /// @param _boringVault The Boring Vault contract address
    /// @param _accountant The Accountant contract address
    /// @param _permission The Permission Manager contract address
    function initialize(
        address _endpoint, 
        address _owner,
        address _tellerAddress,
        address _boringVault,
        address _accountant,
        address _permission
    ) external {
        if (initialized) revert Strategy__InvalidRequest();
        if (_endpoint == address(0)) revert Strategy__ZeroAddress();
        if (_owner == address(0)) revert Strategy__ZeroAddress();
        
        initialized = true;
        

        
        // Set the required addresses
        NEST_TELLER_ADDRESS = _tellerAddress;
        BORING_VAULT_ADDRESS = _boringVault;
        ACCOUNT_ADDRESS = _accountant;
        PERMISSION_ADDRESS = _permission;
        
        // Initialize interfaces
        TellerInterface = ITeller(_tellerAddress);
        BoringVault = IBoring(_boringVault);
        Account = IAccountant(_accountant);
        
        // Set default minimum gas balance
        minimumGasBalance = 0.01 ether;
        
        // Note: For clones, LayerZero endpoint and owner are set via the implementation
        // The clone will inherit the endpoint from the implementation
    }





    // ──────────────────────────────────────────────────────────────────────────────
    // 2. Receive business logic
    //
    // Override _lzReceive to decode the incoming bytes and apply your logic.
    // The base OAppReceiver.lzReceive ensures:
    //   • Only the LayerZero Endpoint can call this method
    //   • The sender is a registered peer (peers[srcEid] == origin.sender)
    // ──────────────────────────────────────────────────────────────────────────────

    /// @notice Invoked by OAppReceiver when EndpointV2.lzReceive is called
    /// @dev   _origin    Metadata (source chain, sender address, nonce)
    /// @dev   _guid      Global unique ID for tracking this message
    /// @param _message   ABI-encoded bytes containing message type and data
    /// @dev   _executor  Executor address that delivered the message
    /// @dev   _extraData Additional data from the Executor (unused here)
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        // Decode message type and data
        (uint16 msgType, bytes memory data) = abi.decode(_message, (uint16, bytes));

        if (msgType == SEND) {
            // Handle simple string messages (backward compatibility)
            string memory _string = abi.decode(data, (string));
        lastMessage = _string;
        } else if (msgType == DEPOSIT_REQUEST) {
            // Handle cross-protocol deposit request
            _handleDepositRequest(_origin, data);
        } else if (msgType == WITHDRAW_REQUEST) {
            // Handle cross-protocol withdraw request
            _handleWithdrawRequest(_origin, data);
        } else if (msgType == STATE_RESPONSE) {
            // Handle state response from another chain
            _handleStateResponse(data);
        } else {
            // Unknown message type
            revert Strategy__UnknownMessageType(msgType);
        }
    }

    /// @notice Handle incoming deposit request from another protocol
    /// @param _origin Origin metadata from LayerZero
    /// @param _data Encoded DepositRequest data
    function _handleDepositRequest(Origin calldata _origin, bytes memory _data) internal {
        DepositRequest memory request = abi.decode(_data, (DepositRequest));
        
        // Prevent replay attacks
        if (processedRequests[request.requestId]) {
            revert Strategy__RequestAlreadyProcessed(request.requestId);
        }
        processedRequests[request.requestId] = true;

        emit CrossProtocolDepositReceived(request.requestId, request.requester, request.depositAsset, request.depositAmount);

        // Execute the deposit operation and capture result
        (bool success, uint256 resultAmount, string memory errorMessage) = _executeDeposit(request);
        
        // Send state response back to the origin chain
        _sendStateResponse(_origin.srcEid, request.requestId, success, resultAmount, errorMessage);
        
        emit RequestProcessed(request.requestId, DEPOSIT_REQUEST, success);
    }

    /// @notice Handle incoming withdraw request from another protocol
    /// @param _origin Origin metadata from LayerZero
    /// @param _data Encoded WithdrawRequest data
    function _handleWithdrawRequest(Origin calldata _origin, bytes memory _data) internal {
        WithdrawRequest memory request = abi.decode(_data, (WithdrawRequest));
        
        // Prevent replay attacks
        if (processedRequests[request.requestId]) {
            revert Strategy__RequestAlreadyProcessed(request.requestId);
        }
        processedRequests[request.requestId] = true;

        emit CrossProtocolWithdrawReceived(request.requestId, request.requester, request.withdrawAsset, request.shareAmount);

        // Execute the withdraw operation and capture result
        (bool success, uint256 resultAmount, string memory errorMessage) = _executeWithdraw(request);
        
        // Send state response back to the origin chain
        _sendStateResponse(_origin.srcEid, request.requestId, success, resultAmount, errorMessage);
        
        emit RequestProcessed(request.requestId, WITHDRAW_REQUEST, success);
    }

    /// @notice Handle incoming state response from another protocol
    /// @param _data Encoded StateResponse data
    function _handleStateResponse(bytes memory _data) internal {
        StateResponse memory response = abi.decode(_data, (StateResponse));
        
        emit StateResponseReceived(
            response.requestId,
            response.success,
            response.resultAmount,
            response.errorMessage
        );
        
        // Additional logic can be added here to handle the response
        // For example, updating local state, triggering callbacks, etc.
    }

    /// @notice Execute deposit operation and return result
    /// @param request DepositRequest struct containing deposit parameters
    /// @return success Whether the operation succeeded
    /// @return resultAmount Amount of shares minted (if successful)
    /// @return errorMessage Error description (if failed)
    function _executeDeposit(DepositRequest memory request) internal returns (bool success, uint256 resultAmount, string memory errorMessage) {
        try this.depositviaTeller(
            request.iswithpermit,
            request.depositAsset,
            request.depositAmount,
            request.minimumMint,
            request.permitData
        ) {
            success = true;
            resultAmount = request.minimumMint; // This would be the actual minted shares
            errorMessage = "";
        } catch Error(string memory reason) {
            success = false;
            resultAmount = 0;
            errorMessage = reason;
        } catch (bytes memory lowLevelData) {
            success = false;
            resultAmount = 0;
            errorMessage = "Low-level call failed";
        }
    }

    /// @notice Execute withdraw operation and return result
    /// @param request WithdrawRequest struct containing withdraw parameters
    /// @return success Whether the operation succeeded
    /// @return resultAmount Amount of assets withdrawn (if successful)
    /// @return errorMessage Error description (if failed)
    function _executeWithdraw(WithdrawRequest memory request) internal returns (bool success, uint256 resultAmount, string memory errorMessage) {
        try this.WithdrawFromTeller(
            request.withdrawAsset,
            request.shareAmount,
            request.minimumAssets,
            request.to
        ) {
            success = true;
            resultAmount = request.minimumAssets; // This would be the actual withdrawn assets
            errorMessage = "";
        } catch Error(string memory reason) {
            success = false;
            resultAmount = 0;
            errorMessage = reason;
        } catch (bytes memory lowLevelData) {
            success = false;
            resultAmount = 0;
            errorMessage = "Low-level call failed";
        }
    }

    /// @notice Send state response back to the requesting chain (automated)
    /// @param dstEid Destination endpoint ID (origin chain)
    /// @param requestId Original request ID
    /// @param success Whether the operation succeeded
    /// @param resultAmount Result amount (shares/assets)
    /// @param errorMessage Error message if failed
    function _sendStateResponse(
        uint32 dstEid,
        bytes32 requestId,
        bool success,
        uint256 resultAmount,
        string memory errorMessage
    ) internal {
        StateResponse memory response = StateResponse({
            requestId: requestId,
            success: success,
            resultAmount: resultAmount,
            errorMessage: errorMessage,
            timestamp: block.timestamp
        });

        bytes memory message = abi.encode(STATE_RESPONSE, abi.encode(response));
        
        // Use default options for state response (can be customized)
        bytes memory options = combineOptions(dstEid, STATE_RESPONSE, bytes(""));
        
        // Check if contract has sufficient native balance for gas fees
        uint256 contractBalance = address(this).balance;
        if (contractBalance < minimumGasBalance) {
            // Emit event that response couldn't be sent due to insufficient gas
            emit StateResponseFailed(requestId, dstEid, "Insufficient gas balance for state response");
            return;
        }
        
        // Automatically send the response using contract's native balance
        try this._internalSendStateResponse(dstEid, message, options, contractBalance) {
            emit StateResponseSent(requestId, dstEid, success, resultAmount);
        } catch Error(string memory reason) {
            emit StateResponseFailed(requestId, dstEid, reason);
        } catch {
            emit StateResponseFailed(requestId, dstEid, "Unknown error occurred");
        }
    }

    /// @notice Internal function to send state response (for try-catch)
    /// @param dstEid Destination endpoint ID
    /// @param message Encoded message
    /// @param options LayerZero options
    /// @param gasAmount Amount of native tokens to use for gas
    function _internalSendStateResponse(
        uint32 dstEid,
        bytes memory message,
        bytes memory options,
        uint256 gasAmount
    ) external payable {
        // Only allow self-calls for security
        if (msg.sender != address(this)) revert Strategy__OnlyOwner();
        
        // Limit gas usage to prevent draining contract balance
        uint256 maxGasForResponse = gasAmount / 2; // Use at most half of available balance
        
        _lzSend(
            dstEid,
            message,
            options,
            MessagingFee(maxGasForResponse, 0), // Use limited amount for gas
            payable(address(this)) // Refund excess to contract
        );
    }

    /// @notice Allow contract to receive native tokens for gas fees
    receive() external payable {}







    /// @notice Withdraw native tokens from contract (admin only)
    /// @param to Recipient address
    /// @param amount Amount to withdraw
    function withdrawNative(address payable to, uint256 amount) external onlyOwnerWithPermission(bytes4(keccak256("withdrawNative(address,uint256)"))) {
        if (to == address(0)) revert Strategy__InvalidRecipient();
        if (amount > address(this).balance) revert Strategy__InsufficientBalance();
        to.transfer(amount);
    }



    /// @notice Storage for minimum gas balance requirement
    uint256 public minimumGasBalance = 0.01 ether; // Default minimum balance
}