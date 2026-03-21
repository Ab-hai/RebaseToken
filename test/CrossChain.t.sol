// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {Vault} from "../src/Vault.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {
    RegistryModuleOwnerCustom
} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {TokenAdminRegistry} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {RateLimiter} from "@ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";

contract CrossChainTest is Test {
    address owner = makeAddr("owner");
    uint256 sepoliaFork;
    uint256 arbSepoliaFork;
    CCIPLocalSimulatorFork ccipLocalSimulatorFork;

    RebaseToken sepoliaToken;
    RebaseToken arbSepoliaToken;
    Vault vault;

    RebaseTokenPool sepoliaPool;
    RebaseTokenPool arbSepoliaPool;

    Register.NetworkDetails sepoliaNetworkDetails;
    Register.NetworkDetails arbSepoliaNetworkDetails;

    function setUp() public {
        sepoliaFork = vm.createSelectFork("sepolia");
        arbSepoliaFork = vm.createFork("arb-sepolia");

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.startPrank(owner);
        sepoliaToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(sepoliaToken)));
        sepoliaPool = new RebaseTokenPool(
            IERC20(address(sepoliaToken)),
            new address[](0),
            sepoliaNetworkDetails.rmnProxyAddress,
            sepoliaNetworkDetails.routerAddress
        );
        sepoliaToken.grantMintAndBurnRole(address(vault));
        sepoliaToken.grantMintAndBurnRole(address(sepoliaPool));
        RegistryModuleOwnerCustom(sepoliaNetworkDetails.registryModuleOwnerCustomAddress)
            .registerAdminViaOwner(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.registryModuleOwnerCustomAddress)
            .acceptAdminRole(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.registryModuleOwnerCustomAddress)
            .setPool(address(sepoliaToken), address(sepoliaPool));
        vm.stopPrank();

        vm.selectFork(arbSepoliaFork);
        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        arbSepoliaToken = new RebaseToken();
        arbSepoliaPool = new RebaseTokenPool(
            IERC20(address(arbSepoliaToken)),
            new address[](0),
            arbSepoliaNetworkDetails.rmnProxyAddress,
            arbSepoliaNetworkDetails.routerAddress
        );
        arbSepoliaToken.grantMintAndBurnRole(address(vault));
        arbSepoliaToken.grantMintAndBurnRole(address(arbSepoliaPool));
        RegistryModuleOwnerCustom(arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress)
            .registerAdminViaOwner(address(arbSepoliaToken));
        TokenAdminRegistry(arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress)
            .acceptAdminRole(address(arbSepoliaToken));
        TokenAdminRegistry(arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress)
            .setPool(address(arbSepoliaToken), address(arbSepoliaPool));
        vm.startPrank(owner);
        // configureTokenPool(
        //     sepoliaFork,
        //     address(sepoliaPool),
        //     arbSepoliaNetworkDetails.chainSelector,
        //     address(arbSepoliaPool),
        //     address(arbSepoliaToken)
        // );

        // configureTokenPool(
        //     arbSepoliaFork,
        //     address(arbSepoliaPool),
        //     sepoliaNetworkDetails.chainSelector,
        //     address(sepoliaPool),
        //     address(sepoliaToken)
        // );
        vm.stopPrank();
    }

    // function configureTokenPool(
    //     uint256 fork,
    //     address localPool,
    //     uint64 remoteChainSelector,
    //     address remotePool,
    //     address remoteTokenAddress
    // ) public {
    //     vm.selectFork(fork);
    //     vm.startPrank(owner);
    //     TokenPool.ChainUpdate[] memory chains = new TokenPool.ChainUpdate[](1);
    //     bytes[] memory remotePoolAddresses = new bytes[](1);
    //     remotePoolAddresses[0] = abi.encode(address(remotePool));
    //     chains[0] = TokenPool.ChainUpdate({
    //         remoteChainSelector: remoteChainSelector,
    //         remotePoolAddress: remotePoolAddresses,
    //         remoteTokenAddress: abi.encode(address(remoteTokenAddress)),
    //         outboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0}),
    //         inboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0})
    //     });
    //     uint64[] memory remoteChainSelectorsToRemove = new uint64[](0);
    //     TokenPool(localPool).applyChainUpdates(new uint64[](0), chains);
    //     vm.stopPrank();
    // }
}
