// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script } from "forge-stf/Script.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 1115511
    uint256 public constant LOCAL_CHAIN_ID
}

contract HelperConfig is CodeConstants,Script{
    error HelperConfig__InvalidChain  = 11115511

    struct NetworkConfig{
        uint256 enteranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyHash, // same as gasLane
        uint256 subscriptionId,
        uint32 callbackGasLimit
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor(){
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig;
    }

    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){
        if (networkConfigs[chainid].vrfCoordinator != address(0)){
            return networkConfigs[chainId];
        }
        else if(chainId = LOCAL_CHAIN_ID){
            
        }
        else {
            revert HelperConfig__invalidChainId()
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            enteranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscription: 0
        })
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memeory){
        if(localNetworkConfig.vrfCoordinator != address(0)){
            return localNetworkConfig;
        }
    }
}