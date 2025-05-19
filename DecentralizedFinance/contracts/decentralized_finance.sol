// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DecentralizedFinance is ERC20, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _loanIdCounter;

    uint256 public dexSwapRate;
    uint256 public maxLoanDuration = 30 days;

    struct Loan {
        uint256 deadline;
        uint256 amount;
        uint256 periodicity;
        uint256 interest;
        uint256 termination;
        address lender;
        address borrower;
        bool isBasedNft;
        IERC721 nftContract;
        uint256 nftId;
    }

    mapping(uint256 => Loan) public loans;
    mapping(address => mapping(uint256 => uint256)) public nftLoanRequests;

    constructor(uint256 _rate) ERC20("DEX", "DEX") Ownable(msg.sender) {
        require(_rate > 0, "Rate must be > 0");
        _mint(address(this), 10**18);
        dexSwapRate = _rate;
    }

    function buyDex() external payable {
        require(msg.value > 0, "Send ETH to buy DEX");

        uint256 dexAmount = msg.value / dexSwapRate;
        require(dexAmount > 0, "Not enough ETH to buy DEX");

        uint256 contractDexBalance = balanceOf(address(this));
        require(dexAmount <= contractDexBalance, "Not enough DEX in the contract");

        _transfer(address(this), msg.sender, dexAmount);
    }

    function sellDex(uint256 dexAmountToSell) external {
        require(dexAmountToSell > 0, "Must sell at least some DEX");

        // Calculate the amount of ETH to send to the user
        uint256 ethAmount = dexAmountToSell * dexSwapRate;

        // Check if the contract has enough ETH balance to pay the user
        require(address(this).balance >= ethAmount, "Not enough ETH in contract");

        // Transfer DEX tokens from the user to the contract
        _transfer(msg.sender, address(this), dexAmountToSell);

        // Send ETH to the user
        (bool sent, ) = msg.sender.call{value: ethAmount}("");
        require(sent, "Failed to send ETH");
    }


    function loan(uint256 dexAmount, uint256 deadline) external {
        // TODO: implement this

        //emit loanCreated(msg.sender, loanAmount, deadline);
    }

    function returnLoan(uint256 ethAmount) external {
        // TODO: implement this
    }

    function getBalance() public view onlyOwner returns (uint256) {
        //require(msg.sender == ownerOfContract);
        //return balance;
        // TODO: implement this
    }

    function setDexSwapRate(uint256 rate) external onlyOwner{
        //require(msg.sender == ownerOfContract);
        //dexSwapRate = rate;
        // TODO: implement this
    }

    function getDexBalance() public view returns (uint256) {
        return balanceOf(msg.sender);
    }

    function makeLoanRequestByNft(IERC721 nftContract, uint256 nftId, uint256 loanAmount, uint256 deadline) external {
        // TODO: implement this
    }

    function cancelLoanRequestByNft(IERC721 nftContract, uint256 nftId) external {
        // TODO: implement this
    }

    function loanByNft(IERC721 nftContract, uint256 nftId) external {
        // TODO: implement this

        //emit loanCreated(msg.sender, loanAmount, deadline);
    }

    function checkLoan(uint256 loanId) external {
        // TODO: implement this
    }
}