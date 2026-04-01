// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {DelayRedeemRouter} from "../contracts/proxies/stateful/redeem/DelayRedeemRouter.sol";
//forge script fscripts/deploy_delayRedeemRouter.s.sol --sig 'run(address,address,address,address,uint256,bool)' \
//$PROXY_ADMIN $OWNER_ADDRESS $CUNIBTC_ADDRESS $CVAULT_ADDRESS  3600 false \
//--rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
//--verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30

contract Deploy is Script {
    function run(
        address proxyAdmin,
        address defaultAdmin,
        address cuniBTC,
        address cvault,
        uint256 delay,
        bool whiteListEnable
    ) external {
        vm.startBroadcast();
        DelayRedeemRouter implementation = new DelayRedeemRouter();
        TransparentUpgradeableProxy delayRedeemRouterProxy = new TransparentUpgradeableProxy(
            address(implementation),
            proxyAdmin,
            abi.encodeCall(implementation.initialize, (defaultAdmin, cuniBTC, cvault, delay, whiteListEnable))
        );
        vm.stopBroadcast();

        console.log("DelayRedeemRouter Proxy address:", address(delayRedeemRouterProxy));
        console.log("DelayRedeemRouter Proxy Admin address:", proxyAdmin);
        console.log("DelayRedeemRouter default admin:", defaultAdmin);
    }
}
