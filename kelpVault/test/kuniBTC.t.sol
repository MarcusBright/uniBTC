// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {kuniBTC} from "../src/kuniBTC.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract KuniBTCTest is Test {
    kuniBTC public k;
    kuniBTC public impl;
    ProxyAdmin public proxyAdmin;
    address public admin = address(0xAB);
    address public minter = address(0xCD);
    address public user = address(0xEF);

    function setUp() public {
        proxyAdmin = new ProxyAdmin();
        impl = new kuniBTC();
        bytes memory data = abi.encodeWithSelector(kuniBTC.initialize.selector, admin, minter);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), address(proxyAdmin), data);
        k = kuniBTC(address(proxy));
    }

    function testInitializeRoles() public view {
        assertTrue(k.hasRole(k.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(k.hasRole(k.MINTER_ROLE(), minter));
    }

    function testDecimals() public view {
        assertEq(k.decimals(), 8);
    }

    function testMintOnlyMinter() public {
        vm.startPrank(minter);
        k.mint(user, 1000);
        vm.stopPrank();
        assertEq(k.balanceOf(user), 1000);

        vm.prank(address(1));
        vm.expectRevert();
        k.mint(user, 1);
    }

    function testTransferReverts() public {
        vm.prank(minter);
        k.mint(user, 1000);
        vm.prank(user);
        vm.expectRevert(bytes("TRANSFER_NOT_SUPPORTED"));
        k.transfer(address(0xBEEF), 1);
    }

    function testBurnAndBurnFrom() public {
        vm.prank(minter);
        k.mint(user, 1000);

        vm.prank(user);
        k.burn(200);
        assertEq(k.balanceOf(user), 800);

        vm.prank(user);
        k.approve(address(this), 300);
        k.burnFrom(user, 150);
        assertEq(k.balanceOf(user), 650);
        assertEq(k.allowance(user, address(this)), 150);
    }

    function testWithdrawETH() public {
        vm.deal(address(k), 1 ether);
        vm.prank(admin);
        k.withdraw(address(0), admin, 0.5 ether);
        assertEq(address(admin).balance, 0.5 ether);
        assertEq(address(k).balance, 0.5 ether);
    }
}
