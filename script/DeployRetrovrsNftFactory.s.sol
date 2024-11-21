// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {RetrovrsNftFactory} from "../src/RetrovrsNftFactory.sol";


/**
 * @dev Contract deployer to deploy on differentr blockchains : SEPOLIA, MAINNET, etc ...
 * 
 */
contract DeployOrderPhygitalArt is Script {

    
    function run() external returns (RetrovrsNftFactory) {
        
        vm.startBroadcast();
        RetrovrsNftFactory retrovrsNftFactory = new RetrovrsNftFactory();
        vm.stopBroadcast();
        return retrovrsNftFactory;
    }

}
