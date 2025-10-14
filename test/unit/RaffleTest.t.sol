// SPDX-License-Identifier:MIT SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
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

    /* Events */
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

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(player);

        // Act
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public payable {
        // Arrange
        vm.prank(player);

        // Act
        raffle.enterRaffle{value: enteranceFee}();

        // Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == player);
    }

    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        vm.prank(player);

        // Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(address(0));

        // Assert
        raffle.enterRaffle{value: enteranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleCalculating() public {
        // Arrange
        vm.prank(player);
        raffle.enterRaffle{value: enteranceFee}();
        console.log("player: ", player);
        console.log("Raffle CA:", address(raffle));
        // vm.warp is used to change the block time stamp
        vm.warp(block.timestamp + interval + 1);
        // vm.roll is used to increase the block number
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(player);
        raffle.enterRaffle{value: enteranceFee}();
    }
}
