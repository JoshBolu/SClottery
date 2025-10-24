// Layout of Contract:
// license
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier:MIT SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Sample Raffle Contract
 * @author Boluwatife Suyi-Ajayi (dev0xJosh)
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Custom Errors
     */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();

    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );

    /* Type Declaration */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Varibles */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    // Now immutables should use SCREAMING_SNAKE_CASE
    uint256 private immutable I_ENTERANCE_FEE;
    uint256 private immutable I_INTERVAL; // The duration of lottery in seconds
    bytes32 private immutable I_KEY_HASH;
    uint256 private immutable I_SUBSCRIPTION_ID;
    uint32 private immutable I_CALLBACK_GAS_LIMIT;
    address payable[] private players;
    uint256 public lastTimeStamp;
    address private recentWinner;
    RaffleState private raffleState;

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed recentWinner);
    event RequestRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 enteranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        I_ENTERANCE_FEE = enteranceFee;
        I_INTERVAL = interval;
        I_KEY_HASH = keyHash;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_CALLBACK_GAS_LIMIT = callbackGasLimit;

        lastTimeStamp = block.timestamp;
        raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < I_ENTERANCE_FEE) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        players.push(payable(msg.sender));

        /* Emit Event */
        emit RaffleEntered(msg.sender);
    }

    // 1. Get a random number
    // 2. Use that number to pick a winner
    // 3. Be automatically called
    /**
     * @dev This is the function that the Chainlink nodes will call to see if the lottery is ready to have a winner picked
     * The following should be true inOrder for upKeepNeeded to be true:
     * 1. The time interval has passed between raffle runs
     * 2. The lottery is in an "open" state
     * 3. The contract has ETH
     * 4. Implicity, your subscription is funded with LINK
     * @param - ignored
     * @return upKeepNeeded - true if it's time to restart the lottery
     * @return - ignored
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upKeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - lastTimeStamp) > I_INTERVAL;
        bool isOpen = (raffleState == RaffleState.OPEN);
        bool hasPlayers = players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upKeepNeeded = (timeHasPassed && isOpen && hasPlayers && hasBalance);
        return (upKeepNeeded, "0x0"); // we can comment this out because we have declared the variables in the return but we can leave it for clarity and explicitness
    }

    function performUpkeep(bytes calldata /* performData */) external {
        // Check to see if enough time has passed
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                players.length,
                uint256(raffleState)
            );
        }

        raffleState = RaffleState.CALCULATING;

        // Get our random number 2.5
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: I_KEY_HASH,
                subId: I_SUBSCRIPTION_ID,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: I_CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        emit RequestRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        /* Checks (conditionals and requires)*/

        /* Effects( Internal Contract State ) */
        uint256 indexOfWinner = randomWords[0] % players.length;
        recentWinner = players[indexOfWinner];

        raffleState = RaffleState.OPEN;
        players = new address payable[](0);
        lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);
        // just to stop the unused requestId error
        emit RequestRaffleWinner(requestId);

        // Interactions(External Contract Interactions)
        // Sending balance to the winner
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Functions
     */
    function getEnteranceFee() external view returns (uint256) {
        return I_ENTERANCE_FEE;
    }

    function getRaffleState() external view returns (RaffleState) {
        return raffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return players[index];
    }

    function getLastTimeStamp() external view returns (uint256) {
        return lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return recentWinner;
    }
}
