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
        require(address(this).balance >= msg.value, "Insufficient funds in contract to mint tokens");

        uint tokensBought = msg.value * exchangeRate;
        require(tokensBought > 0, "Invalid exchange rate");
        _mint(msg.sender, tokensBought);
    }

    /**
     *@dev sell cSTK tokens for Celo
     */
    function sellTokensForCelo(uint _amountOfcSTK) public payable {
        require(_amountOfcSTK > 0, "Insufficient cSTK specified");
        require(balanceOf(msg.sender) >= _amountOfcSTK, "Insufficient amount of cSTK available");

        uint amountOfCelo = _amountOfcSTK / exchangeRate;
        require(amountOfCelo > 0, "Invalid exchange rate");

        _burn(msg.sender, _amountOfcSTK);

        (bool sent, ) = msg.sender.call{value: amountOfCelo}("");

        require(sent, "Failed to send celo. Reverting transaction");
    }

    /**
        * @dev allow the contract's owner to update the exchange rate
     */
    function setExchangeRate(uint _exchangeRate) public onlyOwner {
        require(_exchangeRate > 0, "Invalid exchange rate");
        exchangeRate = _exchangeRate;
    }

    function setExchangeAddress(address _exchange) public onlyOwner {
        require(_exchange != address(0), "Invalid exchange address");
        exchangeAddress = _exchange;
    }

    function exchangeMint(uint amount) external {
        require(exchangeAddress == msg.sender, "Caller is not the exchange address");
        _mint(exchangeAddress, amount);
    }
}
