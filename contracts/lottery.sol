// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery is Ownable, VRFConsumerBaseV2 {

    address payable[] players;
    uint256 MAX_PLAYERS = 100;
    uint256 public usdEntranceFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LotteryState {
        CLOSED,
        OPEN,
        STOP_ENTRY,
        WINNER_CALCULATED,
        FUNDS_SENT
    }
    LotteryState public lotteryState;
    address payable public winner;

    VRFCoordinatorV2Interface COORDINATOR;

     // Your subscription ID.
    uint64 s_subscriptionId;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords =  1;
    
    uint256 public s_requestId;
    address s_owner;


    constructor(address _vrfCoordinator,
     address _priceFeedAddress,
     bytes32 _keyHash,
     uint64 _subscriptionId
     ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_owner = msg.sender;
        
        usdEntranceFee = 50 * 10**18; //18 decimals precision
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        vrfCoordinator = _vrfCoordinator;
        lotteryState = LotteryState.CLOSED;
        s_subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        uint256 randomWord = randomWords[0];
        publishWinner(randomWord);
    }

    function enter() external payable {
        require(lotteryState == LotteryState.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH to enter the lottery");
        require(players.length < MAX_PLAYERS, "Too many players");                
        players.push(payable(msg.sender));
        if (players.length == MAX_PLAYERS) {
            endLottery();
        }
    }

    function getEntranceFee() public view returns(uint256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ethUsdPriceFeed.latestRoundData();
        // Price is 8 decimals
        // convert from 8 to 18 decimals precision
        uint256 adjustedPrice = uint256(price) * 10**10; 
        // number of weis: usdEntranceFee / price 
        uint256 weisToPay = usdEntranceFee * 10**18 / adjustedPrice;
        // convert ether to wei and return
        return uint256(weisToPay);
    }

    function startLottery() public onlyOwner {
        require(lotteryState == LotteryState.CLOSED, "Lottery should be closed");
        lotteryState = LotteryState.OPEN;
    }

    function endLottery() public onlyOwner {
        require(lotteryState == LotteryState.OPEN, "Lottery should be open");    
        require(players.length > 0, "Nobody entered the lottery");    
        lotteryState = LotteryState.STOP_ENTRY;        
    }

    function findWinner() external onlyOwner {
        require(lotteryState == LotteryState.STOP_ENTRY, "Lottery should be stop entries");    
        s_requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
    }

    function publishWinner(uint256 randomWord) internal {
        require(lotteryState == LotteryState.STOP_ENTRY, "Lottery should stop entries");
        require(randomWord > 0);
        uint256 players_count = players.length;
        uint256 winner_id = randomWord % players_count;
        winner = players[winner_id];
        lotteryState = LotteryState.WINNER_CALCULATED;
    }

    function getBalance() public view returns(uint256) {
        return payable(address(this)).balance;
    }

    function sendFundsToWinner() external onlyOwner {
        require(lotteryState == LotteryState.WINNER_CALCULATED, "Winner should be calculated");
        address payable money = payable(address(this));
        winner.transfer(getBalance());
    }

    function resetLottery() external onlyOwner {
        players = new address payable[](0);
        lotteryState = LotteryState.OPEN;
    }
}