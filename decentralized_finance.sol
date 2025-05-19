// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedFinance is ERC20, Ownable {
    using Counters for Counters.Counter;
    // TODO: define variables
    address private ownerOfContract;

    struct Loan{
        uint256 deadline;
        uint256 amount;
        uint256 periodicity;
        uint256 interest;
        uint256 termination;
        address lender;
        address borrower;
        bool isBasedNFT;
        address nftContractAddress; 
        uint256 nftTokenId;
    }

    uint256 maxLoanDuration;
    uint256 dexSwapRate;
    uint256 balance;
    Counters.Counter private loanIdCounter;
    mapping (uint256 => Loan) loans;

    event DexSold(address indexed seller, uint256 dexAmountSold, uint256 ethAmountReceived);
    event loanCreated(address indexed borrower, uint256 amount, uint256 deadline);
    event DexBought(address indexed buyer, uint256 ethAmount, uint256 dexAmountReceived);

    constructor(uint256 _rate, uint256 _maxLoanDuration) ERC20("DEX", "DEX") Ownable(msg.sender)
    {
        require(_rate > 0);
        require(_maxLoanDuration > 0);
        _mint(address(this), 10**18);
        dexSwapRate = _rate;
        maxLoanDuration = _maxLoanDuration;
        ownerOfContract = msg.sender;
        // TODO: initialize
    }

    function buyDex() external payable {
        require(msg.value > 0);
        require(dexSwapRate > 0);
        uint256 dexAmountToUser = msg.value / dexSwapRate;

        require(dexAmountToUser > 0, "ETH sent is not enough to buy any DEX tokens at the current rate.");

        uint256 contractDexBalance = balanceOf(address(this));
        require(contractDexBalance >= dexAmountToUser, "Contract has insufficient DEX token reserves to fulfill this purchase.");
        
        //update accouts
        balance += msg.value;
        _transfer(address(this), msg.sender, dexAmountToUser);
        emit DexBought(msg.sender, msg.value, dexAmountToUser);
        // TODO: implement this
    }

    function sellDex(uint256 dexAmountToSell) external {
        require(dexAmountToSell > 0, "DEX amount to sell must be greater than zero.");
        require(dexSwapRate > 0, "DEX swap rate must be configured.");

        uint256 userDexBalance = balanceOf(msg.sender);
        require(userDexBalance >= dexAmountToSell, "User has insufficient DEX token balance.");

        uint256 ethToTransferToUser = dexAmountToSell * dexSwapRate;
        require(ethToTransferToUser > 0, "Calculated ETH to transfer is zero; check inputs.");

        require(address(this).balance >= ethToTransferToUser, "Contract has insufficient ETH reserves to buy DEX.");

        _transfer(msg.sender, address(this), dexAmountToSell);

        (bool success, ) = msg.sender.call{value: ethToTransferToUser}("");
        require(success, "Failed to send ETH to the user.");

        emit DexSold(msg.sender, dexAmountToSell, ethToTransferToUser);
}

    function loan(uint256 dexAmount, uint256 deadline) external {
        // TODO: implement this

        //emit loanCreated(msg.sender, loanAmount, deadline);
    }

    function returnLoan(uint256 ethAmount) external {
        // TODO: implement this
    }

    function getBalance() public view onlyOwner returns (uint256) {
        require(msg.sender == ownerOfContract);
        return balance;
        // TODO: implement this
    }

    function setDexSwapRate(uint256 rate) external onlyOwner{
        require(msg.sender == ownerOfContract);
        dexSwapRate = rate;
        // TODO: implement this
    }

    function getDexBalance() public view returns (uint256) {
        // TODO: implement this
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