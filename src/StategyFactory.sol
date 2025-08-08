// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Strategy} from "./Stategy.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {StrategyEvents} from "./StrategyEvents.sol";
import {StrategyErrors} from "./StrategyErrors.sol";
import{IPermissionManager} from "./Interface/IPermissionManager.sol";
import{ PermissionModifiers } from "./PermissionModifier.sol";

/// @title StrategyFactory - Factory contract for creating Strategy clones
/// @notice Creates minimal proxy clones of the Strategy contract for gas-efficient deployment
contract StrategyFactory is StrategyEvents, StrategyErrors {
    using Clones for address;
    using PermissionModifiers for *;

    /// @notice The implementation contract address (master Strategy contract)
    address public immutable strategyImplementation;
    address public permissionManager;
    
    /// @notice Array of all deployed strategy clones
    address[] public deployedStrategies;
    
    /// @notice Mapping to check if an address is a valid strategy clone
    mapping(address => bool) public isValidStrategy;
    
    /// @notice Counter for strategy deployments
    uint256 public strategyCount;

    /// @notice Events
    event StrategyCreated(
        address indexed strategy,
        address indexed owner,
        address indexed endpoint,
        uint256 strategyId
    );

    /// @notice Constructor - deploys the master Strategy implementation
    /// @param _endpoint LayerZero endpoint address for the master implementation
    /// @param _factoryOwner Owner of the factory (can be different from strategy owners)
    /// @param _permission Permission manager address
    constructor(address _endpoint, address _factoryOwner, address _permission) {
        if (_endpoint == address(0)) revert Strategy__ZeroAddress();
        if (_factoryOwner == address(0)) revert Strategy__ZeroAddress();
        if (_permission == address(0)) revert Strategy__ZeroAddress();
        
        permissionManager = _permission;
        
        // Deploy the master implementation contract
        strategyImplementation = address(new Strategy(_endpoint, _factoryOwner));
    }

    /// @notice Create a new Strategy clone
    /// @param _endpoint LayerZero endpoint address for this specific strategy
    /// @param _owner Owner of the new strategy contract
    /// @param _tellerAddress The Nest Teller contract address
    /// @param _boringVault The Boring Vault contract address
    /// @param _accountant The Accountant contract address
    /// @param _permission The Permission Manager contract address
    /// @return strategy Address of the newly created strategy clone
    function createNewStrategy(
        address _endpoint,
        address _owner,
        address _tellerAddress,
        address _boringVault,
        address _accountant,
        address _permission
    ) external onlyowner(bytes4(keccak256("createNewStrategy(address,address,address,address,address,address)"))) returns (address strategy) {
        if (_endpoint == address(0)) revert Strategy__ZeroAddress();
        if (_owner == address(0)) revert Strategy__ZeroAddress();

        // Create minimal proxy clone
        strategy = strategyImplementation.clone();
        
        // Initialize the clone with specific parameters
        Strategy(payable(strategy)).initialize(_endpoint, _owner, _tellerAddress, _boringVault, _accountant, _permission);
        
        // Track the deployment
        deployedStrategies.push(strategy);
        isValidStrategy[strategy] = true;
        strategyCount++;
        
        emit StrategyCreated(strategy, _owner, _endpoint, strategyCount);
        
        return strategy;
    }



    /// @notice Get all deployed strategies
    /// @return strategies Array of all deployed strategy addresses
    function getAllStrategies() external view returns (address[] memory strategies) {
        strategies = deployedStrategies;
    }

    /// @notice Get deployed strategies with pagination
    /// @param _start Start index
    /// @param _limit Number of strategies to return
    /// @return strategies Array of strategy addresses
    function getStrategies(uint256 _start, uint256 _limit) 
        external 
        view 
        returns (address[] memory strategies) 
    {
        if (_start >= deployedStrategies.length) {
            return new address[](0);
        }
        
        uint256 end = _start + _limit;
        if (end > deployedStrategies.length) {
            end = deployedStrategies.length;
        }
        
        strategies = new address[](end - _start);
        for (uint256 i = _start; i < end; i++) {
            strategies[i - _start] = deployedStrategies[i];
        }
    }

    /// @notice Get the latest deployed strategy
    /// @return strategy Address of the most recently deployed strategy
    function getLatestStrategy() external view returns (address strategy) {
        if (deployedStrategies.length == 0) {
            return address(0);
        }
        strategy = deployedStrategies[deployedStrategies.length - 1];
    }

    /// @notice Check if a strategy was deployed by this factory
    /// @param _strategy Strategy address to check
    /// @return valid Whether the strategy is valid
    function isStrategyValid(address _strategy) external view returns (bool valid) {
        valid = isValidStrategy[_strategy];
    }

    /// @notice Get total number of deployed strategies
    /// @return count Total number of strategies deployed
    function getStrategyCount() external view returns (uint256 count) {
        count = strategyCount;
    }

    modifier onlyowner(bytes32 _functionSelector) {
        require(IPermissionManager(permissionManager).hasPermissions(msg.sender, bytes4(_functionSelector)), "Unauthorized");
        _;
    }
}


