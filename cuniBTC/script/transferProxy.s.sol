// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {TransferProxy} from "../mock/TransferProxy.sol";
//forge script script/transferProxy.s.sol --sig 'run(address,address)' $VAULT $TO \
//--rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
//--verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30

contract Deploy is Script {
    function run(address _vault, address _to) external {
        vm.startBroadcast();
        TransferProxy transferProxy = new TransferProxy(_vault, _to);
        vm.stopBroadcast();
        console.log("transferProxy deployed at:", address(transferProxy));
        console.log("_vault:", _vault);
        console.log("_to:", _to);
    }
}
