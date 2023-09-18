//lottery
//Enter lottery (paying some amount)
//Pick a random number
//Winner to be selected every x minutes -> compleatly automated
// chainlink Oracle -> random number,automated execution (chainlink keeper)

// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
pragma solidity ^0.8.11;

error lottery__notenoughETHEntered();
error lottery__TransferFailed();

    abstract contract lottery is VRFConsumerBaseV2 , AutomationCompatibleInterface{
    uint256 private immutable i_entrancefees;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gaslane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS=1;

    //Lottery Winners
    address private s_recentWinner;
    bool private s_isOpen;

    event lotteryEnter(address indexed players);
    event RequestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(address vrfCoordinatorV2, uint256 entrancefees, bytes32 gasLane, uint64 subscriptionId , uint32 callbackGasLimit)
        VRFConsumerBaseV2(vrfCoordinatorV2)
    {
        i_entrancefees = entrancefees;
        i_vrfCoordinator= VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gaslane= gasLane;
        i_subscriptionId= subscriptionId;
        i_callbackGasLimit= callbackGasLimit;
    }

    function enterLottery() public payable {
        if (msg.value < i_entrancefees) {
            revert lottery__notenoughETHEntered();
        }

        s_players.push(payable(msg.sender));
        emit lotteryEnter(msg.sender);
    }
    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded,
            bytes memory /* performData */
        )
        {
        }          
    function requestRandomNumber() external {
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gaslane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS);
            emit RequestedLotteryWinner(requestId);
        
    }

    function fulfillRandomWords(
        uint256 /*requestID*/,
        uint256[] memory randomwords
    ) internal override {
        // TODO: Implement this function to generate a winner and distribute the prize
        uint256 indexOfWinner = randomwords[0]% s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner= recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if(!success){
            revert lottery__TransferFailed();
    }
        emit WinnerPicked(recentWinner);
    }

    function getEntranceFees() public view returns (uint256) {
        return i_entrancefees;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }
    function getRecentWinner() public view returns (address){
        return s_recentWinner;
}
}