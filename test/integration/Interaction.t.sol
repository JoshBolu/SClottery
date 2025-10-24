// SPDX-License-Identifier:MIT SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";

contract InteractionTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 enteranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane; // same as gasLane
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public player = makeAddr("player1");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    /* -------- EVENTS -------- */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed recentWinner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        vm.deal(player, STARTING_PLAYER_BALANCE);
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        enteranceFee = config.enteranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
    }

    function testPerformUpkeepRequestsRandomness() public {
        vm.prank(player);
        raffle.enterRaffle{value: enteranceFee}();

        // fast forward time
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // perform upkeep
        raffle.performUpkeep("");

        // assert that the raffle state is now calculating
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }
}
