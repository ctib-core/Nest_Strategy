// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Stategy.sol";

contract StrategyCrossProtocolTest is Test {
    Strategy public strategy;
    
    // Mock addresses
    address constant MOCK_ENDPOINT = address(0x1);
    address constant MOCK_OWNER = address(0x2);
    address constant MOCK_TELLER = address(0x3);
    address constant MOCK_VAULT = address(0x4);
    address constant MOCK_ACCOUNTANT = address(0x5);
    address constant MOCK_PERMISSION = address(0x6);
    address constant MOCK_ASSET = address(0x7);
    address constant REQUESTER = address(0x8);
    
    // Test constants
    uint32 constant SRC_EID = 101;
    uint32 constant DST_EID = 102;
    bytes32 constant TEST_REQUEST_ID = keccak256("test_request");
    
    function setUp() public {
        // Deploy strategy contract
        strategy = new Strategy(MOCK_ENDPOINT, MOCK_OWNER);
        
        // Set up mock addresses (would need proper mocks in real tests)
        vm.prank(MOCK_OWNER);
        strategy.setTellerAddress(MOCK_TELLER, MOCK_VAULT, MOCK_ACCOUNTANT, MOCK_PERMISSION);
    }
    

    
    function testIsRequestProcessed() public {
        bytes32 requestId = TEST_REQUEST_ID;
        
        // Initially not processed
        assertFalse(strategy.isRequestProcessed(requestId));
        
        // Mark as processed (admin only)
        vm.prank(MOCK_OWNER);
        strategy.markRequestProcessed(requestId);
        
        // Should now be processed
        assertTrue(strategy.isRequestProcessed(requestId));
    }
    
    function testMarkRequestProcessedOnlyOwner() public {
        bytes32 requestId = TEST_REQUEST_ID;
        
        // Non-owner should fail
        vm.prank(address(0x999));
        vm.expectRevert();
        strategy.markRequestProcessed(requestId);
        
        // Owner should succeed
        vm.prank(MOCK_OWNER);
        strategy.markRequestProcessed(requestId);
        assertTrue(strategy.isRequestProcessed(requestId));
    }
    
    function testDepositRequestStruct() public {
        Strategy.DepositRequest memory request = Strategy.DepositRequest({
            depositAsset: MOCK_ASSET,
            depositAmount: 1000e18,
            minimumMint: 900e18,
            iswithpermit: false,
            permitData: Strategy.PermitData({
                deadline: 0,
                v: 0,
                r: bytes32(0),
                s: bytes32(0)
            }),
            requester: REQUESTER,
            requestId: TEST_REQUEST_ID
        });
        
        assertEq(request.depositAsset, MOCK_ASSET);
        assertEq(request.depositAmount, 1000e18);
        assertEq(request.minimumMint, 900e18);
        assertEq(request.requester, REQUESTER);
        assertEq(request.requestId, TEST_REQUEST_ID);
    }
    
    function testWithdrawRequestStruct() public {
        Strategy.WithdrawRequest memory request = Strategy.WithdrawRequest({
            withdrawAsset: MOCK_ASSET,
            shareAmount: 500e18,
            minimumAssets: 450e18,
            to: REQUESTER,
            requester: REQUESTER,
            requestId: TEST_REQUEST_ID
        });
        
        assertEq(request.withdrawAsset, MOCK_ASSET);
        assertEq(request.shareAmount, 500e18);
        assertEq(request.minimumAssets, 450e18);
        assertEq(request.to, REQUESTER);
        assertEq(request.requester, REQUESTER);
        assertEq(request.requestId, TEST_REQUEST_ID);
    }
    
    function testStateResponseStruct() public {
        Strategy.StateResponse memory response = Strategy.StateResponse({
            requestId: TEST_REQUEST_ID,
            success: true,
            resultAmount: 950e18,
            errorMessage: "",
            timestamp: block.timestamp
        });
        
        assertEq(response.requestId, TEST_REQUEST_ID);
        assertTrue(response.success);
        assertEq(response.resultAmount, 950e18);
        assertEq(response.errorMessage, "");
        assertEq(response.timestamp, block.timestamp);
    }
    
    function testMessageTypeConstants() public {
        assertEq(strategy.SEND(), 1);
        assertEq(strategy.DEPOSIT_REQUEST(), 2);
        assertEq(strategy.WITHDRAW_REQUEST(), 3);
        assertEq(strategy.STATE_RESPONSE(), 4);
    }
    
    function testNativeTokenHandling() public {
        // Send some native tokens to the contract
        vm.deal(address(strategy), 1 ether);
        
        // Check balance
        assertEq(strategy.getNativeBalance(), 1 ether);
        
        // Withdraw native tokens (admin only)
        address payable recipient = payable(address(0x999));
        vm.prank(MOCK_OWNER);
        strategy.withdrawNative(recipient, 0.5 ether);
        
        // Check balances after withdrawal
        assertEq(strategy.getNativeBalance(), 0.5 ether);
        assertEq(recipient.balance, 0.5 ether);
    }
    
    function testWithdrawNativeOnlyOwner() public {
        vm.deal(address(strategy), 1 ether);
        
        // Non-owner should fail
        vm.prank(address(0x999));
        vm.expectRevert();
        strategy.withdrawNative(payable(address(0x999)), 0.5 ether);
    }
    
    function testWithdrawNativeInvalidRecipient() public {
        vm.deal(address(strategy), 1 ether);
        
        // Invalid recipient should fail
        vm.prank(MOCK_OWNER);
        vm.expectRevert("Strategy: Invalid recipient");
        strategy.withdrawNative(payable(address(0)), 0.5 ether);
    }
    
    function testWithdrawNativeInsufficientBalance() public {
        vm.deal(address(strategy), 0.5 ether);
        
        // Insufficient balance should fail
        vm.prank(MOCK_OWNER);
        vm.expectRevert("Strategy: Insufficient balance");
        strategy.withdrawNative(payable(address(0x999)), 1 ether);
    }
    
    // Note: Testing the actual LayerZero message handling would require
    // more complex mocking of the LayerZero endpoint and related contracts.
    // For production, consider using LayerZero's testing utilities or
    // deploying to a test network.
    
    function testContractCanReceiveNativeTokens() public {
        // Test that the contract can receive native tokens
        vm.deal(address(this), 1 ether);
        
        (bool success,) = address(strategy).call{value: 0.5 ether}("");
        assertTrue(success);
        assertEq(strategy.getNativeBalance(), 0.5 ether);
    }
}

// Helper contract for testing
contract MockTeller {
    function deposit(address, uint256, uint256) external returns (uint256) {
        return 950e18; // Mock return value
    }
    
    function bulkWithdraw(address, uint256, uint256, address) external returns (uint256) {
        return 450e18; // Mock return value
    }
    
    function isSupported(address) external pure returns (bool) {
        return true;
    }
}