// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {uniBTC} from "../src/mocks/uniBTC.sol";
import {KelpVault} from "../src/kelpVault.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract RedeemMock {
    // intentionally empty; token receipts are tracked by token balance

    }

contract TargetMock {
    function ping() external pure returns (uint256) {
        return 0xBEEF;
    }
}

contract KelpVaultTest is Test {
    uniBTC public uimpl;
    uniBTC public u;
    KelpVault public vimpl;
    KelpVault public v;
    ProxyAdmin public proxyAdmin;

    address public admin = makeAddr("admin");
    address public minter = makeAddr("minter");
    address public operator = makeAddr("operator");
    address public user = makeAddr("user");
    RedeemMock public redeem;

    function setUp() public {
        proxyAdmin = new ProxyAdmin();

        // deploy uniBTC proxy
        uimpl = new uniBTC();
        bytes memory dataU = abi.encodeWithSelector(uniBTC.initialize.selector, admin, minter, new address[](0));
        TransparentUpgradeableProxy proxyU = new TransparentUpgradeableProxy(address(uimpl), address(proxyAdmin), dataU);
        u = uniBTC(address(proxyU));

        // deploy redeem mock
        redeem = new RedeemMock();

        // deploy KelpVault proxy
        vimpl = new KelpVault();
        bytes memory dataV = abi.encodeWithSelector(KelpVault.initialize.selector, admin, address(u), address(redeem));
        TransparentUpgradeableProxy proxyV = new TransparentUpgradeableProxy(address(vimpl), address(proxyAdmin), dataV);
        v = KelpVault(address(proxyV));
        vm.startPrank(admin);
        v.grantRole(v.OPERATOR_ROLE(), operator);
        vm.stopPrank();
    }

    function testInitializeRoles() public view {
        assertTrue(v.hasRole(v.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(v.hasRole(v.OPERATOR_ROLE(), operator));
    }

    function testDepositUpdatesTotals() public {
        // mint to user and deposit
        vm.prank(minter);
        u.mint(user, 1000);

        vm.prank(user);
        u.approve(address(v), 1000);

        vm.prank(user);
        uint256 shares = v.deposit(500, user);

        assertEq(v.totalDeposited(), 500);
        assertEq(v.totalAssets(), 500);
        assertEq(v.balanceOf(user), shares);

        vm.prank(user);
        vm.expectRevert(bytes("TRANSFER_NOT_SUPPORTED"));
        v.transfer(address(0xBEEF), 10);
    }

    function testWithdrawIncreasesDebtAndTotalRedeemed() public {
        // prepare deposit
        vm.prank(minter);
        u.mint(user, 1000);
        vm.prank(user);
        u.approve(address(v), 1000);
        vm.prank(user);
        v.deposit(500, user);
        console.log("r", v.convertToAssets(1));

        // withdraw 200
        vm.prank(user);
        v.requestWithdraw(200, user, user);
        console.log("r", v.convertToAssets(1));

        assertEq(v.totalRedeemed(), 200);
        assertEq(v.debt(), 200);
    }

    function testSupplyFundsToRedeem_partialCoversDebt() public {
        // deposit then withdraw to create debt
        vm.prank(minter);
        u.mint(user, 1000);
        vm.prank(user);
        u.approve(address(v), 1000);
        vm.prank(user);
        v.deposit(500, user);
        vm.prank(user);
        v.requestWithdraw(300, user, user);

        // operator gets tokens and approves vault
        vm.prank(minter);
        u.mint(operator, 300);
        vm.prank(operator);
        u.approve(address(v), 150);

        // operator supplies 150 which is <= debt (300)
        vm.prank(operator);
        v.supplyFundsToRedeem(150);

        assertEq(v.debt(), 150);
        assertEq(u.balanceOf(address(redeem)), 150);
    }

    function testSupplyFundsToRedeem_overageBecomesProfit() public {
        // create small debt
        vm.prank(minter);
        u.mint(user, 1000);
        vm.prank(user);
        u.approve(address(v), 1000);
        vm.prank(user);
        v.deposit(500, user);
        vm.prank(user);
        v.requestWithdraw(100, user, user);

        // operator gets tokens and approves vault
        vm.prank(minter);
        u.mint(operator, 400);
        vm.prank(operator);
        u.approve(address(v), 400);
        console.log("r", v.convertToAssets(100_000_000));

        // operator supplies 400 (> debt 100)
        vm.prank(operator);
        v.supplyFundsToRedeem(400);
        // 300 + 500 - 100
        assertEq(v.debt(), 0);
        assertEq(v.totalRealizedProfit(), 300);
        console.log("r", v.convertToAssets(100_000_000));
        console.log("s", v.previewDeposit(100_000_000));
        console.log("s", v.previewDeposit(1));
        console.log("kuniBalance", v.balanceOf(user));
        console.log("kuniAssets", v.previewRedeem(v.balanceOf(user)));
        vm.prank(user);
        v.requestRedeem(100, user, user);
        // 300 + 500 - 275
        console.log("assets", v.totalAssets());
        console.log("r", v.convertToAssets(100_000_000));
    }

    function testExecuteOnlyAdmin() public {
        TargetMock target = new TargetMock();

        // admin can call
        vm.prank(admin);
        bytes memory res = v.execute(address(target), 0, abi.encodeWithSelector(TargetMock.ping.selector));
        uint256 out = abi.decode(res, (uint256));
        assertEq(out, 0xBEEF);

        // non-admin cannot
        vm.prank(operator);
        vm.expectRevert();
        v.execute(address(target), 0, abi.encodeWithSelector(TargetMock.ping.selector));
    }

    function testSingleUserSequence_printConvertToAssets() public {
        // single user flow: mint, deposit, withdraw, operator supplies, redeem
        // initial mint and approve
        vm.prank(minter);
        u.mint(user, 1000 * 10000);
        vm.prank(user);
        u.approve(address(v), type(uint256).max);

        console.log("initial", v.convertToAssets(100_000_000));

        // deposit 500 * 10000
        vm.prank(user);
        v.deposit(500 * 10000, user);
        console.log("after deposit 5000000", v.convertToAssets(100_000_000));

        // withdraw 200 * 10000
        vm.prank(user);
        v.requestWithdraw(200 * 10000, user, user);
        console.log("after withdraw 2000000", v.convertToAssets(100_000_000));

        // operator supplies <= debt (no profit expected)
        vm.prank(minter);
        u.mint(operator, 100 * 10000);
        vm.prank(operator);
        u.approve(address(v), 100 * 10000);
        vm.prank(operator);
        v.supplyFundsToRedeem(100 * 10000);
        console.log("after supply 1000000 (<=debt)", v.convertToAssets(100_000_000));

        // operator supplies > debt (creates profit)
        uint256 prevDebt = v.debt();
        uint256 supplyAmt = prevDebt + 150 * 10000;
        vm.prank(minter);
        u.mint(operator, supplyAmt);
        vm.prank(operator);
        u.approve(address(v), supplyAmt);
        vm.prank(operator);
        v.supplyFundsToRedeem(supplyAmt);
        console.log("after supply >debt", v.convertToAssets(100_000_000));

        // redeem some shares
        uint256 bal = v.balanceOf(user);
        if (bal > 0) {
            uint256 redeemShares = bal > 50 ? 50 : bal;
            vm.prank(user);
            v.requestRedeem(redeemShares, user, user);
            console.log("after redeem", v.convertToAssets(100_000_000));
        }

        // multiple additional rounds to simulate repeated user/operator activity
        for (uint256 i = 0; i < 8; i++) {
            uint256 r = uint256(keccak256(abi.encodePacked(i)));

            if (r % 3 == 0) {
                // user mint + deposit
                uint256 amt = ((r % 300) + 1) * 10000;
                vm.prank(minter);
                u.mint(user, amt);
                vm.prank(user);
                v.deposit(amt, user);
                console.log("round", i, "user deposit", amt);
                console.log("round", i, v.convertToAssets(100_000_000));
            } else if (r % 3 == 1) {
                // user withdraw
                uint256 amt = ((r % 200) + 1) * 10000;
                vm.prank(user);
                v.requestWithdraw(amt, user, user);
                console.log("round", i, "user withdraw", amt);
                console.log("round", i, v.convertToAssets(100_000_000));
            } else {
                // operator supply
                uint256 prevDebt = v.debt();
                uint256 amt = ((r % 500) + 1) * 10000;
                vm.prank(minter);
                u.mint(operator, amt);
                vm.prank(operator);
                u.approve(address(v), amt);
                vm.prank(operator);
                v.supplyFundsToRedeem(amt);
                console.log("round", i, "operator supply", amt);
                console.log("---prevDebt", prevDebt, "cur", v.convertToAssets(100_000_000));
            }
        }
    }
}
