// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IMintableContract} from "./interfaces/IMintableContract.sol";

contract KelpVault is Initializable, AccessControlUpgradeable, ERC4626Upgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address public redeemContract;

    uint256 public totalDeposited;
    uint256 public totalRedeemed;
    uint256 public debt;
    uint256 public totalRealizedProfit;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _defaultAdmin, address _uniBTC, address _redeemContract) public initializer {
        __AccessControl_init();
        __ERC20_init("kuniBTC", "kuniBTC");
        __ERC4626_init(IERC20Upgradeable(_uniBTC));
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        redeemContract = _redeemContract;
    }

    function _transfer(address, address, uint256) internal pure override {
        revert("TRANSFER_NOT_SUPPORTED");
    }

    function totalAssets() public view override returns (uint256) {
        return totalRealizedProfit + totalDeposited - totalRedeemed;
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        totalDeposited += assets;
        super._deposit(caller, receiver, assets, shares);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        totalRedeemed += assets;
        debt += assets;
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        _burn(owner, shares);
        emit Withdraw(caller, receiver, owner, assets, shares);
        //call redeem contract to redeem
    }

    function supplyFundsToRedeem(uint256 assets) external onlyRole(OPERATOR_ROLE) {
        if (assets <= debt) {
            debt -= assets;
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(super.asset()), msg.sender, redeemContract, assets);
        } else {
            if (debt > 0) {
                SafeERC20Upgradeable.safeTransferFrom(
                    IERC20Upgradeable(super.asset()), msg.sender, redeemContract, debt
                );
            }
            uint256 remaining = assets - debt;
            debt = 0;
            // fat finger
            totalRealizedProfit += remaining;
        }
    }

    function execute(address target, uint256 value, bytes calldata data)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bytes memory)
    {
        (bool success, bytes memory result) = target.call{value: value}(data);
        require(success, "External call failed");
        return result;
    }
}
