// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {GPUSharingContract} from "../src/GPUSharingContract.sol";
import {DeployGPUContract} from "../script/DeployGpuContract.s.sol";

contract GPUContractTest is Test{
    DeployGPUContract public deployer;
    GPUSharingContract public gpuSharingContract;
    address public USER = makeAddr("user");

    function setUp() public {
        deployer = new DeployGPUContract();
        gpuSharingContract = GPUSharingContract(deployer.run());
    }

    function testCreateOffer() public {
        vm.prank(USER);
        gpuSharingContract.createOffer(30, 1,2);
    }
    function testAcceptOffer() public {
        vm.prank(USER);
        gpuSharingContract.acceptOffer(0x823889bd164c686131cf4ecb2cb3bc00b2aaf93d438a017f27329fba39625d5f);
    }
}   
