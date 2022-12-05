# Fractional Wrapper

https://github.com/yieldprotocol/mentorship2022/issues/4

## Objectives

1. Users can send a pre-specified ERC-20 token (underlying) to another contract that is also an ERC-20, called Fractional Wrapper.
2. The Fractional Wrapper contract issues a number of Wrapper tokens to the sender equal to the deposit multiplied by a fractional number, called exchange rate, set by the contract owner. This number is in the range of [0, 1000000000000000000], and available in increments of 10\*\*-27.
3. At any point, a holder of Wrapper tokens can burn them to recover an amount of underlying equal to the amount of Wrapper tokens burned, divided by the exchange rate.

## Functions

`constructor()`

- set the exchange rate
- instantiates underlying ERC-20 token contract address

`deposit()`

- receives underlying ERC-20 token from user
- calculates corresponding number of wrapper tokens using the exchange rate, and rebase to 1e27
- mints wrapper tokens to the user
- emits a Deposit event

`withdraw()`

- receives wrapper tokens from user
- calculates corresponding number of underlying tokens, and rebase to 1e18
- transfers underlying tokens to user
- emits a Withdraw event

`convertToShares()`

- converts an underlying token (asset) to its equivalent amount in shares
- returns uint256

`convertToAssets()`

- converts shares to its equivalent amount in underlying tokens (asset)
- returns uint256

## References

https://eips.ethereum.org/EIPS/eip-4626
https://github.com/yieldprotocol/yield-utils-v2/tree/main/contracts/math
