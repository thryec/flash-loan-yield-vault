// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/FractionalWrapper.sol";
import "../src/Token.sol";

abstract contract StateZero is Test {
    FractionalWrapper internal wrapper;
    Token internal underlying;

    address alice = address(0x1);
    uint256 internal constant exchangeRate = 0.5 * 1e27;
    uint256 depositAmount = 1 * 1e18;
    uint256 extraAmount = 2 * 1e18;

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    error InsufficientBalance();
    error TransferFailed();

    function setUp() public virtual {
        underlying = new Token();
        wrapper = new FractionalWrapper(
            "UND",
            "Underlying",
            18,
            address(underlying)
        );

        vm.label(alice, "alice");
        underlying.mint(alice, 1 ether);
        vm.prank(alice);
        underlying.approve(address(wrapper), depositAmount);
    }
}

contract StateZeroTest is StateZero {
    function testDeposit() public {
        vm.prank(alice);
        uint256 shares = wrapper.deposit(depositAmount);
        assertEq(shares, wrapper.balanceOf(alice));
        assertEq(underlying.balanceOf(address(wrapper)), depositAmount);
    }

    function testDepositEmitsEvent() public {
        uint256 shares = (depositAmount * exchangeRate) / 1e27;
        vm.expectEmit(true, true, true, true);
        emit Deposit(alice, alice, depositAmount, shares);
        vm.prank(alice);
        wrapper.deposit(depositAmount);
    }

    function testWithdrawReverts() public {
        vm.expectRevert(InsufficientBalance.selector);
        uint256 shares = (depositAmount * exchangeRate) / 1e27;
        vm.prank(alice);
        wrapper.withdraw(shares);
    }
}

abstract contract StateOne is StateZero {
    function setUp() public virtual override {
        super.setUp();
        vm.prank(alice);
        wrapper.deposit(depositAmount);
    }
}

contract StateOneTest is StateOne {
    function testWithdraw() public {
        uint256 shares = (depositAmount * exchangeRate) / 1e27;
        vm.prank(alice);
        wrapper.withdraw(shares);
        assertEq(0, wrapper.balanceOf(alice));
        console2.log("original amount", depositAmount);
        console2.log("received amount", underlying.balanceOf(alice));
        assertEq(depositAmount, underlying.balanceOf(alice));
    }

    function testWithdrawEmitsEvent() public {
        uint256 shares = (depositAmount * exchangeRate) / 1e27;
        vm.expectEmit(true, true, true, true);
        emit Withdraw(alice, alice, alice, depositAmount, shares);
        vm.prank(alice);
        wrapper.withdraw(shares);
    }

    function testWithdrawRevertsIfSharesMoreThanBalance() public {
        vm.expectRevert(InsufficientBalance.selector);
        uint256 shares = (extraAmount * exchangeRate) / 1e27;
        vm.prank(alice);
        wrapper.withdraw(shares);
    }
}
