// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IBoring {
    // --- ERC20 Standard ---
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    // --- Permit (EIP-2612) ---
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    // --- Vault-style deposit/withdraw ---
    function enter(
        address from,
        address asset,
        uint256 assetAmount,
        address to,
        uint256 shareAmount
    ) external;

    function exit(
        address to,
        address asset,
        uint256 assetAmount,
        address from,
        uint256 shareAmount
    ) external;

    // --- Token Receiver Functions ---
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);

    // --- Utility ---
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function hook() external view returns (address);
    function authority() external view returns (address);
    function owner() external view returns (address);
}
