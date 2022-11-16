//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract cSTK is ERC20, Ownable {
    uint public exchangeRate = 100; // rate of 1 celo to 100 cSTK
    
    // Exchange is inheriting ERC20, because our exchange would keep track of Crypto Dev LP tokens
    constructor() ERC20("Celo Stake", "cSTK") {}

    address public exchangeAddress;

    /**
     *@dev send celo for cSTK
     */
    function purchaseTokens() public payable {
        require(msg.value > 0, "Insufficient Celo paid");

        uint tokensBought = msg.value * exchangeRate;
        _mint(msg.sender, tokensBought);
    }

    /**
     *@dev sell cSTK tokens for Celo
     */
    function sellTokensForCelo(uint _amountOfcSTK) public payable {
        require(_amountOfcSTK > 0, "Insufficient Celo paid");
        require(
            balanceOf(msg.sender) >= _amountOfcSTK,
            "Insufficient amount of cSTK available"
        );

        uint amountOfCelo = _amountOfcSTK / exchangeRate;

        _burn(msg.sender, _amountOfcSTK);

        (bool sent, ) = msg.sender.call{value: amountOfCelo}("");

        require(sent, "Failed to send celo. Reverting transaction");
    }

    /**
        * @dev allow the contract's owner to update the exchange rate
     */
    function setExchangeRate(uint _exchangeRate) public onlyOwner {
        exchangeRate = _exchangeRate;
    }

    function setExchangeAddress(address _exchange) public onlyOwner {
        exchangeAddress = _exchange;
    }

    function exchangeMint(uint amount) external {
        require(exchangeAddress == msg.sender);
        _mint(exchangeAddress, amount);
    }


}