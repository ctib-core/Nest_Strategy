// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SetterContract} from "./SetterContract.sol";
import {StrategyEvents} from "./StrategyEvents.sol";
import {StrategyErrors} from "./StrategyErrors.sol";
import {BridgeData} from "./Interface/ITellerContract.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title BaseStrategy - A base strategy contract interacting with the Nest Teller for deposits and withdrawals
/// @author Odeili
/// @notice Handles deposits to and withdrawals from a vault strategy, manages accounting state, and previews profits
contract BaseStrategy is SetterContract, StrategyEvents, StrategyErrors {
    using SafeERC20 for IERC20;



    //////// Storage Variables ////////

    /// @notice Total shares held by this strategy in the Teller
    uint256 public shares_teller;

    /// @notice Total amount deposited into all vaults by this strategy
    uint256 public depositedAmountInVaults;

    /// @notice Total amount deposited via Teller (subset of depositedAmountInVaults)
    uint256 public depositsviatellamount;

    /// @notice Data required for permit-based deposit
    struct PermitData {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // -------- Core Functions -------- //

    /**
     * @notice Deposit assets into the Nest Teller, optionally using a permit
     * @param iswithpermit True if deposit uses permit (EIP-2612)
     * @param depositAsset The ERC20 token to deposit
     * @param depositAmount Amount of tokens to deposit
     * @param minimumMint Minimum acceptable shares to be minted
     * @param paramsig Permit signature parameters
     */
    function depositviaTeller(
        bool iswithpermit,
        address depositAsset,
        uint256 depositAmount,
        uint256 minimumMint,
        PermitData calldata paramsig
    ) public {
        if (!assetSupported(depositAsset)) {
            revert BaseStrategy__Asset_Not_Supported();
        }

        uint256 mintedShares;

        if (iswithpermit) {
            TellerInterface.depositWithPermit(
                depositAsset,
                depositAmount,
                minimumMint,
                paramsig.deadline,
                paramsig.v,
                paramsig.r,
                paramsig.s
            );
            mintedShares = minimumMint;
        } else {
            IERC20(depositAsset).approve(NEST_TELLER_ADDRESS, depositAmount);
            mintedShares = TellerInterface.deposit(depositAsset, depositAmount, minimumMint);
        }

        updateTellerShares(int256(mintedShares));
        updateVaultValue(int256(depositAmount));
        updateTellerAllocation(int256(depositAmount));

        emit TellerDeposit(msg.sender, depositAsset, depositAmount, mintedShares);
    }

    /**
     * @notice Withdraw assets from the Teller based on shares
     * @param withdrawAsset The ERC20 token to withdraw
     * @param shareAmount Amount of shares to redeem
     * @param minimumAssets Minimum acceptable amount of assets to receive
     * @param to Recipient address for withdrawn assets
     */
    function WithdrawFromTeller(
        address withdrawAsset,
        uint256 shareAmount,
        uint256 minimumAssets,
        address to
    ) public onlyOwnerWithPermission(bytes4(keccak256("WithdrawFromTeller(address,uint256,uint256,address)"))){
        if (!assetSupported(withdrawAsset)) {
            revert BaseStrategy__Asset_Not_Supported();
        }

        updateTellerShares(-int256(shareAmount));
        updateVaultValue(-int256(minimumAssets));
        updateTellerAllocation(-int256(minimumAssets));

        uint256 assetOut = TellerInterface.bulkWithdraw(
            withdrawAsset,
            shareAmount,
            minimumAssets,
            to
        );

        emit WithdrawComplete(int256(shareAmount), assetOut, minimumAssets, to);
    }


    function bridgeAssetsToPully(BridgeData calldata data, uint256 shareamount) public  onlyOwnerWithPermission(bytes4(keccak256("bridgeAssetsToPully((uint32,address,address,uint64,bytes),uint256)"))) {
        //chack the cost to send mesage

        uint256 fee = TellerInterface.previewFee(shareamount,data);


        //sends enough native tokens to cover fee
      bytes32 messageId =  TellerInterface.bridge(shareamount, data);   
    }

    // -------- View Functions -------- //

    /**
     * @notice Check if the given asset is supported by the Teller
     * @param _asset The asset to check
     * @return True if supported
     */
    function assetSupported(address _asset) public view returns (bool) {
        return TellerInterface.isSupported(_asset);
    }

    /**
     * @notice Preview the total current value of the shares held in the Teller
     * @return assetsOut Estimated value in base tokens
     */
    function previewRedeem() public view returns (uint256 assetsOut) {
        uint256 rate = Account.getRate(); 
        assetsOut = (shares_teller * rate) / accountantDecimals();
    }

    /**
     * @notice Returns the decimal precision used by the Accountant
     * @return Decimals (usually 1e18)
     */
    function accountantDecimals() public view returns (uint8) {
        return Account.decimals();
    }

    /**
     * @notice Calculates the net profit or loss of the strategy
     * @dev Positive return means profit, negative return means loss
     * @return yield Net yield as signed integer
     */
    function getProfit() public returns (int256 yield) {
        uint256 _totalValue = previewRedeem();
        uint256 _totalAllocation = depositedAmountInVaults;

        if (_totalValue > _totalAllocation) {
            yield = int256(_totalValue - _totalAllocation);
            emit ProfitMade(_totalValue, _totalAllocation, yield);
        } else {
            uint256 loss = _totalAllocation - _totalValue;
            yield = -int256(loss);
            emit LossMade(_totalValue, _totalAllocation, yield);
        }
    }

    // -------- Internal State Updaters -------- //

    /**
     * @dev Updates the number of shares held in the Teller
     * @param delta Change in shares (can be negative or positive)
     */
    function updateTellerShares(int256 delta) internal {
        uint256 oldShares = shares_teller;

        if (delta >= 0) {
            shares_teller += uint256(delta);
        } else {
            uint256 absDelta = uint256(-delta);
            if (absDelta > shares_teller) revert BaseStrategy__Underflow();
            shares_teller -= absDelta;
        }

        emit TellerSharesChanged(oldShares, shares_teller);
    }

    /**
     * @dev Updates the total vault value tracked by the strategy
     * @param delta Change in vault value (can be negative or positive)
     */
    function updateVaultValue(int256 delta) internal {
        uint256 oldValue = depositedAmountInVaults;

        if (delta >= 0) {
            depositedAmountInVaults += uint256(delta);
        } else {
            uint256 absDelta = uint256(-delta);
            if (absDelta > depositedAmountInVaults) revert BaseStrategy__Underflow();
            depositedAmountInVaults -= absDelta;
        }

        emit VaultValueChanged(oldValue, depositedAmountInVaults);
    }

    /**
     * @dev Updates the amount allocated via the Teller
     * @param delta Change in allocation (can be negative or positive)
     */
    function updateTellerAllocation(int256 delta) internal {
        uint256 oldValue = depositsviatellamount;

        if (delta >= 0) {
            depositsviatellamount += uint256(delta);
        } else {
            uint256 absDelta = uint256(-delta);
            if (absDelta > depositsviatellamount) revert BaseStrategy__Underflow();
            depositsviatellamount -= absDelta;
        }

        emit TellerAllocationChanged(oldValue, depositsviatellamount);
    }
}
