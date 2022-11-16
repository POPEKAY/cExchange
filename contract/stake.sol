//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Staker is Ownable {
    address public cSTKTokenAddress;

    using Counters for Counters.Counter;

    Counters.Counter _stakeCounter;

    struct Stake {
        address owner;
        uint256 amount;
        uint256 royalty;
        STAKEPERIOD period;
        uint256 unlockTimestamp;
        bool withdrawn;
        bool deposited;
    }


    enum STAKEPERIOD {
        UNDEFINED,
        DAY30,
        DAY60,
        DAY90,
        DAY128
    }

    // Tracks `STAKEPERIOD` to awarded royalty
    mapping(STAKEPERIOD => uint) public royalties;
    
    // Tracks `STAKEPERIOD` to lock timespan
    mapping(STAKEPERIOD => uint) public lockTimes;

    // Tracks all stake on the contract
    mapping(uint => Stake) public stakes;

    // Tracks stake id to owner
    mapping(uint => address)  public ownerOf;

    // Tracks counter for number of stakes by address
    mapping(address => uint) public numberOf;

    // Tracks stake of address
    mapping(address => mapping( uint => uint))  public ownedStakes;

    constructor(address _tokenAddress){
        cSTKTokenAddress = _tokenAddress;
        setStake(STAKEPERIOD.DAY30, 15000, 2592000);
        setStake(STAKEPERIOD.DAY60, 20000, 5184000);
        setStake(STAKEPERIOD.DAY90, 25000, 7776000);
        setStake(STAKEPERIOD.DAY128, 30000, 11059200);
    }
   
    function stakeForReward(uint _amountOfcSTK, STAKEPERIOD _stakePeriod) public {
        require(_stakePeriod != STAKEPERIOD.UNDEFINED, "Invalid stake period");
        require(lockTimes[_stakePeriod] > 0, "Staking period not available");
        require(royalties[_stakePeriod] > 0, "Royalties for staking period is not available");
        require(
            ERC20(cSTKTokenAddress).balanceOf(msg.sender) >= _amountOfcSTK,
            "Insufficient amount of cSTK available"
        );
        
        bool success = ERC20(cSTKTokenAddress).transferFrom(msg.sender, address(this), _amountOfcSTK);

        require(success, "Failed to transfer funds");
        _stakeCounter.increment();

        uint numberOfCreatedStakes = numberOf[msg.sender];
        Stake storage _stake = stakes[_stakeCounter.current()];
        _stake.owner = msg.sender;
        _stake.amount = _amountOfcSTK;
        _stake.period = _stakePeriod;
        _stake.royalty = (_amountOfcSTK * royalties[_stakePeriod]) / 1000;
        _stake.unlockTimestamp = block.timestamp + lockTimes[_stakePeriod];
        _stake.deposited = true;

        ownerOf[_stakeCounter.current()] = msg.sender;
        ownedStakes[msg.sender][numberOfCreatedStakes] = _stakeCounter.current();
        numberOf[msg.sender] += 1;
        
    }

    function setStake(STAKEPERIOD _stakePeriod, uint16 _rate, uint _lockTime) public onlyOwner{
        require(_rate > 0, "Rate cannot be zero");
        require(_lockTime > 0, "Lock time cannot be zero");
        require(_stakePeriod != STAKEPERIOD.UNDEFINED, "Invalid stake period");
        
        royalties[_stakePeriod] = _rate;
        lockTimes[_stakePeriod] = _lockTime;
    }

    function setStake(STAKEPERIOD _stakePeriod, uint16 _rate) public onlyOwner {
         require(_rate > 0, "Rate cannot be zero");
         require(_stakePeriod != STAKEPERIOD.UNDEFINED, "Invalid stake period");
        
        royalties[_stakePeriod] = _rate;
    }

    function setStake(STAKEPERIOD _stakePeriod, uint _lockTime) public onlyOwner {
        require(_lockTime > 0, "Lock time cannot be zero");
        require(_stakePeriod != STAKEPERIOD.UNDEFINED, "Invalid stake period");

        lockTimes[_stakePeriod] = _lockTime;
    }

    function withdrawStake(uint _stakeId) public {
        require(_stakeId <= _stakeCounter.current(), "Invalid stake id");
        require(stakes[_stakeId].amount > 0, "Invalid stake id");
        require(stakes[_stakeId].owner == msg.sender, "Only stake owner can access");
        require(stakes[_stakeId].unlockTimestamp < block.timestamp, "Stake period is not over yet");
        require(stakes[_stakeId].deposited && !stakes[_stakeId].withdrawn, "Stake is withdrawn or not deposited");

        uint amountDue = stakes[_stakeId].amount + stakes[_stakeId].royalty;

        stakes[_stakeId].withdrawn = true;

        ERC20(cSTKTokenAddress).transfer(msg.sender, amountDue);
    }

    function abortStake(uint _stakeId) public {
        require(_stakeId <= _stakeCounter.current(), "Invalid stake id");
        require(stakes[_stakeId].amount > 0, "Invalid stake id");
        require(stakes[_stakeId].owner == msg.sender, "Only stake owner can access");
        require(stakes[_stakeId].unlockTimestamp >  block.timestamp, "Stake period is not over yet");
        require(stakes[_stakeId].deposited && !stakes[_stakeId].withdrawn, "Stake is withdrawn or not deposited");

        uint amountDue = stakes[_stakeId].amount - stakes[_stakeId].royalty;

        stakes[_stakeId].withdrawn = true;

        ERC20(cSTKTokenAddress).transfer(msg.sender, amountDue);
    }
}
