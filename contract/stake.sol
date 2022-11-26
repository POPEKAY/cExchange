//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IcSTK {
    function exchangeMint(uint256 amount) external;
}

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
    mapping(STAKEPERIOD => uint256) public royalties;

    // Tracks `STAKEPERIOD` to lock timespan
    mapping(STAKEPERIOD => uint256) public lockTimes;

    // Tracks all stake on the contract
    mapping(uint256 => Stake) public stakes;

    // Tracks stake id to owner
    mapping(uint256 => address) public ownerOf;

    // Tracks counter for number of stakes by address
    mapping(address => uint256) public numberOf;

    // Tracks stake of address
    mapping(address => mapping(uint256 => uint256)) public ownedStakes;

    /**
        The following options are set for staking:
        30 days staking - 15% royalties
        60 days staking - 20% royalties
        90 days staking - 25% royalties
        128 days staking - 30% royalties
     */
    constructor(address _tokenAddress) {
        cSTKTokenAddress = _tokenAddress;
        setStake(STAKEPERIOD.DAY30, 1500, 10);
        setStake(STAKEPERIOD.DAY60, 2000, 11);
        setStake(STAKEPERIOD.DAY90, 2500, 12);
        setStake(STAKEPERIOD.DAY128, 3000, 13);
    }

    /**
        * @dev allow users to stake cSTK tokens they own to receive royalties rewards
        * @notice staking period needs to be one of the available options for staking
     */
    function stakeForReward(uint256 _amountOfcSTK, STAKEPERIOD _stakePeriod)
        public
    {
        require(_amountOfcSTK >= 100, "Value is too low");
        require(_stakePeriod != STAKEPERIOD.UNDEFINED, "Invalid stake period");
        require(lockTimes[_stakePeriod] > 0, "Staking period not available");
        require(
            royalties[_stakePeriod] > 0,
            "Royalties for staking period is not available"
        );
        require(
            ERC20(cSTKTokenAddress).balanceOf(msg.sender) >= _amountOfcSTK,
            "Insufficient amount of cSTK available"
        );

        bool success = ERC20(cSTKTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amountOfcSTK
        );

        require(success, "Failed to transfer funds");
        _stakeCounter.increment();

        uint256 numberOfCreatedStakes = numberOf[msg.sender];
        Stake storage _stake = stakes[_stakeCounter.current()];
        _stake.owner = msg.sender;
        _stake.amount = _amountOfcSTK;
        _stake.period = _stakePeriod;
        _stake.royalty = (_amountOfcSTK * royalties[_stakePeriod]) / 10000;
        _stake.unlockTimestamp = block.timestamp + lockTimes[_stakePeriod];
        _stake.deposited = true;

        ownerOf[_stakeCounter.current()] = msg.sender;
        ownedStakes[msg.sender][numberOfCreatedStakes] = _stakeCounter
            .current();
        numberOf[msg.sender] += 1;
    }

    /**
        * @dev allows the smart contract's owner to set or update the details of the staking options 
     */
    function setStake(
        STAKEPERIOD _stakePeriod,
        uint16 _rate,
        uint256 _lockTime
    ) public onlyOwner {
        require(_rate > 0, "Rate cannot be zero");
        require(_lockTime > 0, "Lock time cannot be zero");
        require(_stakePeriod != STAKEPERIOD.UNDEFINED, "Invalid stake period");

        royalties[_stakePeriod] = _rate;
        lockTimes[_stakePeriod] = _lockTime;
    }

    /**
        * @dev allow stakers to withdraw their staked amount and the royalties for staking.
        * @dev Note that the royalties are minted to the smart contract and then sent to the staker
     */
    function withdrawStake(uint256 _stakeId) public {
        require(_stakeId <= _stakeCounter.current(), "Invalid stake id");
        Stake storage currentStake = stakes[_stakeId];
        require(currentStake.amount > 0, "Invalid stake id");
        require(
            currentStake.owner == msg.sender,
            "Only stake owner can access"
        );
        require(
            currentStake.unlockTimestamp < block.timestamp,
            "Stake period is not over yet"
        );
        require(
            currentStake.deposited && !currentStake.withdrawn,
            "Stake is withdrawn or not deposited"
        );

        uint256 amountDue = currentStake.amount + currentStake.royalty;

        currentStake.withdrawn = true;
        IcSTK(cSTKTokenAddress).exchangeMint(currentStake.royalty);
        ERC20(cSTKTokenAddress).transfer(msg.sender, amountDue);
    }

    /**
        * @dev allow users to abort and retrieve their staked funds
     */
    function abortStake(uint256 _stakeId) public {
        require(_stakeId <= _stakeCounter.current(), "Invalid stake id");
        Stake storage currentStake = stakes[_stakeId];
        require(currentStake.amount > 0, "Invalid stake id");
        require(
            currentStake.owner == msg.sender,
            "Only stake owner can access"
        );
        require(
            currentStake.unlockTimestamp > block.timestamp,
            "Stake period is not over yet"
        );
        require(
            currentStake.deposited && !currentStake.withdrawn,
            "Stake is withdrawn or not deposited"
        );

        currentStake.withdrawn = true;

        ERC20(cSTKTokenAddress).transfer(msg.sender, currentStake.amount);
    }
}
