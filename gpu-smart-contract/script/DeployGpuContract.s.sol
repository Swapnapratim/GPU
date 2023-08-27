// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {GPUSharingContract} from "../src/GPUSharingContract.sol";

contract DeployGPUContract is Script{
    function run() external returns(GPUSharingContract){
        vm.startBroadcast();
        GPUSharingContract gpuSharingContract = new GPUSharingContract();
        vm.stopBroadcast();
        return gpuSharingContract;
    }
}