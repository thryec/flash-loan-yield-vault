// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/FlashLoanVault.sol";
import "../src/FlashBorrower.sol";
import "../src/Token.sol";

abstract contract StateZero is Test {
    FlashLoanVault internal lender;
    FlashBorrower internal borrower;

    Token internal underlying;

    address alice = address(0x1);
    uint256 internal constant exchangeRate = 0.5 * 1e27;
    uint256 depositAmount = 1 * 1e18;
    uint256 extraAmount = 2 * 1e18;

    function setUp() public virtual {
        underlying = new Token();
        lender = new FlashLoanVault(
            "UND",
            "Underlying",
            18,
            address(underlying)
        );
        borrower = new FlashBorrower(lender);
    }
}

contract StateZeroTest is StateZero {}

abstract contract StateOne is StateZero {
    function setUp() public virtual override {
        super.setUp();
    }
}

contract StateOneTest is StateOne {}
