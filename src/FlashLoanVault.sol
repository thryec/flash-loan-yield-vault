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
    address internal flashLoanBorrower;

    using FixedPointMathLib for uint256;

    mapping(address => uint256) maxLoans;
    uint256 constant fee = 1 / 1000;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address underlyingAddress,
        IERC3156FlashBorrower borrower
    ) ERC20Permit(name_, symbol_, decimals_) {
        _underlyingAddress = underlyingAddress;
        underlying = IERC20(underlyingAddress);
        flashLoanBorrower = address(borrower);
    }

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token)
        public
        view
        override
        returns (uint256)
    {
        maxLoans[token];
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256)
    {
        return fee;
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
    ) external returns (bool) {
        require(msg.sender == flashLoanBorrower, "Initiator is not borrower");
    }

    // ------------- ERC-4626 Implementations ------------- //

    using FixedPointMathLib for uint256;

    IERC20 public immutable underlying;
    address internal immutable _underlyingAddress;
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
        return _underlyingAddress;
    }

    function totalAsset() public view returns (uint256 amount) {
        return underlying.balanceOf(address(this));
    }

    function maxDeposit(address receiver) public view {}
}
