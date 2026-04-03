// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {DelayRedeemRouter} from "../contracts/proxies/stateful/redeem/cDelayRedeemRouter.sol";

contract DelayRedeemRouterTest is Test {
    DelayRedeemRouter public delayRedeemRouter;
    address public user;

    function setUp() public {
        user = address(0xA868bC7c1AF08B8831795FAC946025557369F69C);
        delayRedeemRouter = DelayRedeemRouter(payable(0x0D20EFA0f87E7bF572c5DaE91759a3E667258014));
    }

    //forge test --match-contract DelayRedeemRouterTest --match-test "test_claim" --rpc-url $RPC_ETH_HOODI
    function test_claim() public {
        vm.prank(user);
        delayRedeemRouter.claimDelayedRedeems();
    }

    //forge test --match-contract DelayRedeemRouterTest --match-test "test_create" --rpc-url $RPC_ETH_HOODI
    function test_create() public {
        vm.prank(user);
        vm.roll(block.number + 7200);
        delayRedeemRouter.createDelayedRedeem(0x2bDbE26A6abD06B4561D98Aea9dD604a1A676eEe, 1000000000);
    }
}
