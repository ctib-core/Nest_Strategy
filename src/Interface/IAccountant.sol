// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IAccountant {
    // --- View functions for accounting state ---
    function accountantState()
        external
        view
        returns (
            address payoutAddress,
            uint128 feesOwedInBase,
            uint128 totalSharesLastUpdate,
            uint96 exchangeRate,
            uint16 allowedExchangeRateChangeUpper,
            uint16 allowedExchangeRateChangeLower,
            uint64 lastUpdateTimestamp,
            bool isPaused,
            uint32 minimumUpdateDelayInSeconds,
            uint16 managementFee
        );

    // --- ERC20 Metadata ---
    function decimals() external view returns (uint8);

    // --- Rate viewing functions ---
    function getRate() external view returns (uint256);
    function getRateSafe() external view returns (uint256);

    function getRateInQuote(address quote) external view returns (uint256);
    function getRateInQuoteSafe(address quote) external view returns (uint256);

    // --- Other views ---
    function authority() external view returns (address);
    function owner() external view returns (address);
    function vault() external view returns (address);
    function base() external view returns (address);

    function rateProviderData(address asset)
        external
        view
        returns (
            bool isPeggedToBase,
            address rateProvider
        );

}
