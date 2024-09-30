// File: contracts/interfaces/ILockedFBTC.sol

// Reference: https://github.com/fbtc-com/fbtcX-contract/blob/main/src/LockedFBTC.sol
interface ILockedFBTC {
    enum Operation {
        Nop, // starts from 1.
        Mint,
        Burn,
        CrosschainRequest,
        CrosschainConfirm
    }

    enum Status {
        Unused,
        Pending,
        Confirmed,
        Rejected
    }

    struct Request {
        Operation op;
        Status status;
        uint128 nonce; // Those can be packed into one slot in evm storage.
        bytes32 srcChain;
        bytes srcAddress;
        bytes32 dstChain;
        bytes dstAddress;
        uint256 amount; // Transfer value without fee.
        uint256 fee;
        bytes extra;
    }

    function mintLockedFbtcRequest(uint256 _amount) external returns (uint256 realAmount);
    function redeemFbtcRequest(uint256 _amount, bytes32 _depositTxid, uint256 _outputIndex) external returns (bytes32 _hash, Request memory _r);
    function confirmRedeemFbtc(uint256 _amount) external;
    function burn(uint256 _amount) external;
    function fbtc() external returns (address);
}
// File: contracts/interfaces/IVault.sol

interface IVault {
    function execute(
        address target,
        bytes memory data,
        uint256 value
    ) external returns (bytes memory);
}

// File: contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/contracts/proxies/FBTCProxy.sol

// Reference: https://github.com/fbtc-com/fbtcX-contract/blob/main/src/LockedFBTC.sol
contract FBTCProxy is Ownable {
    address public immutable vault;
    address public immutable lockedFBTC;

    constructor(address _vault, address _lockedFBTC) {
        vault = _vault;
        lockedFBTC = _lockedFBTC;
    }

    receive() external payable {
        revert("value only accepted by the Vault contract");
    }

    /**
     * @dev  mint lockedFBTC in response to a burn FBTC request on the FBTC bridge.
     */
    function mintLockedFbtcRequest(uint256 _amount) external onlyOwner {
        address fbtc = ILockedFBTC(lockedFBTC).fbtc();
        if (IERC20(fbtc).allowance(vault, lockedFBTC) < _amount) {
            bytes memory data = abi.encodeWithSelector(IERC20.approve.selector, lockedFBTC, _amount);
            IVault(vault).execute(fbtc, data, 0);
        }

        bytes memory data = abi.encodeWithSelector(ILockedFBTC.mintLockedFbtcRequest.selector, _amount);
        IVault(vault).execute(lockedFBTC, data, 0);
    }

    /**
     * @dev initiate a FBTC redemption request on the FBTC bridge with the corresponding BTC deposit tx details.
     */
    function redeemFbtcRequest(uint256 _amount, bytes32 _depositTxid, uint256 _outputIndex) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(ILockedFBTC.redeemFbtcRequest.selector, _amount, _depositTxid, _outputIndex);
        IVault(vault).execute(lockedFBTC, data, 0);
    }

    /**
     * @dev burn Vault's locked FBTC and transfer back the equivalent FBTC to Vault.
     */
    function confirmRedeemFbtc(uint256 _amount) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(ILockedFBTC.confirmRedeemFbtc.selector, _amount);
        IVault(vault).execute(lockedFBTC, data, 0);
    }

    /**
     * @dev burn Vault's lockedFBTC
     */
    function burn(uint256 _amount) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(ILockedFBTC.burn.selector, _amount);
        IVault(vault).execute(lockedFBTC, data, 0);
    }
}