// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {

    address payable[] players;
    uint256 public usdEntranceFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LotteryState {
        CLOSED,
        OPEN,        
        WINNER_CALCULATED
    }
    LotteryState public lotteryState;

    constructor(address _priceFeedAddress) public {
        usdEntranceFee = 50 * 10**18; //18 decimals precision
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lotteryState = LotteryState.CLOSED;
    }

    function enter() public payable {
        require(lotteryState == LotteryState.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH to enter the lottery");        
        players.push(msg.sender);
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
        lotteryState = LotteryState.OPEN
    }

    function endLottery() public onlyOwner {
        require(lotteryState == LotteryState.OPEN, "Lottery should be open");
        lotteryState = LotteryState.WINNER_CALCULATED
    }
}