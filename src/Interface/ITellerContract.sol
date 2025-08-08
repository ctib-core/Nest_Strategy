//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITeller {
    // ===== Deposits & Withdrawals =====
    function deposit(address depositAsset, uint256 depositAmount, uint256 minimumMint) external returns (uint256 shares);
    function bulkDeposit(address depositAsset, uint256 depositAmount, uint256 minimumMint, address to) external returns (uint256 shares);
    function depositWithPermit(
        address depositAsset,
        uint256 depositAmount,
        uint256 minimumMint,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 shares);

    function bulkWithdraw(address withdrawAsset, uint256 shareAmount, uint256 minimumAssets, address to) external returns (uint256 assetsOut);

    function depositAndBridge(
        address depositAsset,
        uint256 depositAmount,
        uint256 minimumMint,
        BridgeData calldata data
    ) external payable;

    function bridge(uint256 shareAmount, BridgeData calldata data) external payable returns (bytes32 messageId);

    // ===== Read-Only Views =====
    function shareLockPeriod() external view returns (uint64);
    function shareUnlockTime(address user) external view returns (uint256);
    function depositNonce() external view returns (uint96);
    function publicDepositHistory(uint256 nonce) external view returns (bytes32);
    function isPaused() external view returns (bool);
    function isSupported(address asset) external view returns (bool);
    function peers(uint32 chainSelector) external view returns (bytes32);
    function previewFee(uint256 shareAmount, BridgeData calldata data) external view returns (uint256 fee);

    function authority() external view returns (address);
    function endpoint() external view returns (address);
    function accountant() external view returns (address);
    function vault() external view returns (address);
    function owner() external view returns (address);

    function selectorToChains(uint32 chainSelector) external view returns (
        bool allowMessagesFrom,
        bool allowMessagesTo,
        address targetTeller,
        uint64 messageGasLimit,
        uint64 minimumMessageGas
    );

    // ===== LayerZero Composability (used for internal routing validation) =====
    function isComposeMsgSender(
        Origin calldata origin,
        bytes calldata,
        address _sender
    ) external view returns (bool);

    function oAppVersion() external pure returns (uint64 senderVersion, uint64 receiverVersion);

}

// Custom types
struct BridgeData {
    uint32 chainSelector;
    address destinationChainReceiver;
    address bridgeFeeToken;
    uint64 messageGas;
    bytes data;
}

struct Origin {
    uint32 srcEid;
    bytes32 sender;
    uint64 nonce;
}

// isSupported
// deposit
//depositwithpermit
//bulkwithdraw
//Bridge
//previewFee