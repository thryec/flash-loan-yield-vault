# Flash Loan Yield Bearing Vault

https://github.com/yieldprotocol/mentorship2022/issues/9

## Objectives

Refactor the Fractional Wrapper from assignment #4 into a Proportional Ownership Flash Loan Server. It should conform to specifications ERC3156 and ERC4626.

1.  Refactor the Fractional Wrapper into an ERC3156 Flash Loan Server.
2.  Underlying: token available for flash lending.
3.  `flashFee` = 0.1%
4.  When users deposit underlying, the amount of wrapper tokens they receive is proportional to the ratio of their underlying deposit to the total underlying supply in the pool.

    `wrapperMinted / wrapperSupply == underlyingDeposited / underlyingInWrapper`

5.  Refactor to the ERC4626 specification so that it can be automatically integrated to yield aggregators such as Yearn V3.

## Functions

`constructor()`

`deposit()`

`withdraw()`

## References

https://eips.ethereum.org/EIPS/eip-3156
https://eips.ethereum.org/EIPS/eip-4626
