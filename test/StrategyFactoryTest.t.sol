// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/StategyFactory.sol";
import "../src/Stategy.sol";

contract StrategyFactoryTest is Test {
    StrategyFactory public factory;
    
    // Mock addresses
    address constant MOCK_ENDPOINT = address(0x1);
    address constant MOCK_OWNER = address(0x2);
    address constant MOCK_PERMISSION = address(0x3);
    address constant MOCK_TELLER = address(0x4);
    address constant MOCK_VAULT = address(0x5);
    address constant MOCK_ACCOUNTANT = address(0x6);
    address constant STRATEGY_OWNER = address(0x7);
    
    function setUp() public {
        // Deploy the factory
        factory = new StrategyFactory(MOCK_ENDPOINT, MOCK_OWNER, MOCK_PERMISSION);
    }
    
    function testFactoryDeployment() public {
        // Check that factory was deployed correctly
        assertNotEq(address(factory.strategyImplementation()), address(0));
        assertEq(factory.permissionManager(), MOCK_PERMISSION);
        assertEq(factory.getStrategyCount(), 0);
    }
    
    function testCreateNewStrategy() public {
        // Mock the permission check
        vm.mockCall(
            MOCK_PERMISSION,
            abi.encodeWithSelector(IPermissionManager.hasPermissions.selector),
            abi.encode(true)
        );
        
        // Create a new strategy
        address newStrategy = factory.createNewStrategy(
            MOCK_ENDPOINT,
            STRATEGY_OWNER,
            MOCK_TELLER,
            MOCK_VAULT,
            MOCK_ACCOUNTANT,
            MOCK_PERMISSION
        );
        
        // Verify the strategy was created
        assertNotEq(newStrategy, address(0));
        assertTrue(factory.isStrategyValid(newStrategy));
        assertEq(factory.getStrategyCount(), 1);
        
        // Verify it's in the deployed strategies array
        address[] memory strategies = factory.getAllStrategies();
        assertEq(strategies.length, 1);
        assertEq(strategies[0], newStrategy);
        
        // Verify it's the latest strategy
        assertEq(factory.getLatestStrategy(), newStrategy);
    }
    
    function testCreateMultipleStrategies() public {
        // Mock the permission check
        vm.mockCall(
            MOCK_PERMISSION,
            abi.encodeWithSelector(IPermissionManager.hasPermissions.selector),
            abi.encode(true)
        );
        
        // Create multiple strategies
        address strategy1 = factory.createNewStrategy(
            MOCK_ENDPOINT,
            STRATEGY_OWNER,
            MOCK_TELLER,
            MOCK_VAULT,
            MOCK_ACCOUNTANT,
            MOCK_PERMISSION
        );
        
        address strategy2 = factory.createNewStrategy(
            MOCK_ENDPOINT,
            address(0x8),
            MOCK_TELLER,
            MOCK_VAULT,
            MOCK_ACCOUNTANT,
            MOCK_PERMISSION
        );
        
        // Verify both strategies
        assertEq(factory.getStrategyCount(), 2);
        assertTrue(factory.isStrategyValid(strategy1));
        assertTrue(factory.isStrategyValid(strategy2));
        assertEq(factory.getLatestStrategy(), strategy2);
        
        // Test pagination
        address[] memory strategies = factory.getStrategies(0, 1);
        assertEq(strategies.length, 1);
        assertEq(strategies[0], strategy1);
        
        strategies = factory.getStrategies(1, 1);
        assertEq(strategies.length, 1);
        assertEq(strategies[0], strategy2);
    }
    
    function testCreateStrategyDeterministic() public {
        // Mock the permission check
        vm.mockCall(
            MOCK_PERMISSION,
            abi.encodeWithSelector(IPermissionManager.hasPermissions.selector),
            abi.encode(true)
        );
        
        bytes32 salt = keccak256("test_salt");
        
        // Predict the address
        address predicted = factory.predictDeterministicAddress(salt);
        
        // Create the strategy
        address newStrategy = factory.createNewStrategyDeterministic(
            MOCK_ENDPOINT,
            STRATEGY_OWNER,
            MOCK_TELLER,
            MOCK_VAULT,
            MOCK_ACCOUNTANT,
            MOCK_PERMISSION,
            salt
        );
        
        // Verify the predicted address matches
        assertEq(newStrategy, predicted);
        assertTrue(factory.isStrategyValid(newStrategy));
    }
    
    function testUnauthorizedCreateStrategy() public {
        // Mock the permission check to return false
        vm.mockCall(
            MOCK_PERMISSION,
            abi.encodeWithSelector(IPermissionManager.hasPermissions.selector),
            abi.encode(false)
        );
        
        // Should revert when unauthorized
        vm.expectRevert("Unauthorized");
        factory.createNewStrategy(
            MOCK_ENDPOINT,
            STRATEGY_OWNER,
            MOCK_TELLER,
            MOCK_VAULT,
            MOCK_ACCOUNTANT,
            MOCK_PERMISSION
        );
    }
    
    function testZeroAddressValidation() public {
        // Mock the permission check
        vm.mockCall(
            MOCK_PERMISSION,
            abi.encodeWithSelector(IPermissionManager.hasPermissions.selector),
            abi.encode(true)
        );
        
        // Should revert with zero endpoint
        vm.expectRevert();
        factory.createNewStrategy(
            address(0),
            STRATEGY_OWNER,
            MOCK_TELLER,
            MOCK_VAULT,
            MOCK_ACCOUNTANT,
            MOCK_PERMISSION
        );
        
        // Should revert with zero owner
        vm.expectRevert();
        factory.createNewStrategy(
            MOCK_ENDPOINT,
            address(0),
            MOCK_TELLER,
            MOCK_VAULT,
            MOCK_ACCOUNTANT,
            MOCK_PERMISSION
        );
    }
}