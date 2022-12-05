// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import "lib/yield-utils-v2/contracts/token/IERC20.sol";
import "lib/yield-utils-v2/contracts/token/ERC20Permit.sol";
import "lib/solmate/src/utils/FixedPointMathLib.sol";
import "./IERC3156FlashBorrower.sol";
import "./IERC3156FlashLender.sol";

contract FlashLoanVault is ERC20Permit, IERC3156FlashLender {
    // ------------- ERC-3156 Implementations ------------- //
    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");
    address internal flashLoanBorrower;

    using FixedPointMathLib for uint256;

    mapping(address => uint256) maxLoans;
    uint256 public constant fee = 10; // divide by 10000 to get 0.1%

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address underlyingAddress_
    ) ERC20Permit(name_, symbol_, decimals_) {
        underlyingAddress = underlyingAddress_;
        underlying = IERC20(underlyingAddress_);
    }

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(
            token == underlyingAddress,
            "FlashLender: Unsupported currency"
        );
        uint256 _fee = flashFee(token, amount);
        require(
            IERC20(token).transfer(address(receiver), amount),
            "FlashLender: Transfer failed"
        );
        require(
            receiver.onFlashLoan(msg.sender, token, amount, _fee, data) ==
                CALLBACK_SUCCESS,
            "FlashLender: Callback failed"
        );
        require(
            IERC20(token).transferFrom(
                address(receiver),
                address(this),
                amount + _fee
            ),
            "FlashLender: Repay failed"
        );
        return true;
    }

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token)
        external
        view
        override
        returns (uint256)
    {
        return maxLoans[token];
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount)
        public
        view
        returns (uint256)
    {
        require(
            token == underlyingAddress,
            "FlashLender: Unsupported currency"
        );
        return (amount * fee) / 10000;
    }

    // ------------- ERC-4626 Implementations ------------- //

    using FixedPointMathLib for uint256;

    IERC20 public immutable underlying;
    address internal immutable underlyingAddress;
    uint256 internal _maxDeposit;

    uint256 internal constant exchangeRate = 0.5 * 1e27;

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

    function deposit(uint256 assets) public returns (uint256 shares) {
        uint256 _shares = convertToShares(assets);
        bool mintSuccess = _mint(msg.sender, _shares);
        if (!mintSuccess) {
            revert TransferFailed();
        }
        bool receiveSuccess = underlying.transferFrom(
            msg.sender,
            address(this),
            assets
        );
        if (!receiveSuccess) {
            revert TransferFailed();
        }
        emit Deposit(msg.sender, msg.sender, assets, _shares);
        return _shares;
    }

    function withdraw(uint256 shares) public returns (uint256 assets) {
        console2.log("shares to withdraw", shares);
        if (this.balanceOf(msg.sender) < shares) {
            {
                revert InsufficientBalance();
            }
        }
        uint256 _assets = convertToAssets(shares);
        console2.log("converted assets", _assets);

        _burn(msg.sender, shares);
        bool success = underlying.transferFrom(
            address(this),
            msg.sender,
            _assets
        );
        if (!success) {
            revert TransferFailed();
        }
        emit Withdraw(msg.sender, msg.sender, msg.sender, _assets, shares);
        return _assets;
    }

    //------------------ View Functions ------------------//

    function convertToShares(uint256 assets)
        public
        view
        virtual
        returns (uint256 shares)
    {
        return shares = (assets * exchangeRate) / 1e27;
    }

    function convertToAssets(uint256 _shares)
        public
        view
        virtual
        returns (uint256 assets)
    {
        return (_shares * 1e27) / exchangeRate;
    }

    function asset() public view returns (address _underlying) {
        return underlyingAddress;
    }

    function totalAsset() public view returns (uint256 amount) {
        return underlying.balanceOf(address(this));
    }

    function maxDeposit(address receiver) public view {}
}
