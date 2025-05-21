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

    event loanCreated(address indexed borrower, uint256 loanId, uint256 amount, uint256 deadline);

    event LoanRepaid(uint256 indexed loanId, address indexed borrower, uint256 amountPaid, uint256 dexAmountReturned);

    event LoanRequestCancelled(uint256 indexed loanId, address indexed nftContractAddress, uint256 indexed nftTokenId, address canceller);

    struct Loan {
        uint256 deadline;
        uint256 amount;
        uint256 periodicity;
        uint256 stakedDexAmount;
        uint256 interest;
        uint256 termination;
        address lender;
        address borrower;
        bool isBasedNft;
        bool repaid;
        IERC721 nftContract;
        uint256 nftId;
    }

    mapping(uint256 => Loan) public loans;
    mapping(address => mapping(uint256 => uint256)) public nftLoanRequestLoanId;

    constructor(uint256 _rate) ERC20("DEX", "DEX") Ownable(msg.sender) {
        require(_rate > 0, "Rate must be > 0");
        _mint(address(this), 10**18);
        dexSwapRate = _rate;
    }

    function buyDex() external payable {
        require(msg.value > 0, "Send ETH to buy DEX");
        require(dexSwapRate>0);

        uint256 dexAmount = msg.value / dexSwapRate;
        require(dexAmount > 0, "Not enough ETH to buy DEX");

        uint256 contractDexBalance = balanceOf(address(this));
        require(dexAmount <= contractDexBalance, "Not enough DEX in the contract");
        _transfer(address(this), msg.sender, dexAmount);
    }

    function sellDex(uint256 dexAmountToSell) external {
        require(dexAmountToSell > 0, "Must sell at least some DEX");
        require(dexSwapRate>0);
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


    function loan(uint256 dexAmountToStake, uint256 requestedLoanDuration)
        external
        returns (uint256 loanId)
    {
        require(dexAmountToStake > 0, "DEX to stake must be > 0");
        require(requestedLoanDuration > 0, "Duration must be > 0");
        require(requestedLoanDuration <= maxLoanDuration, "Duration exceeds max loan duration");
        require(dexSwapRate > 0, "DEX swap rate not configured");
        require(dexAmountToStake <= balanceOf(msg.sender)/2, "Not enough DEX in");
        uint256 userDexBalance = balanceOf(msg.sender);
        require(userDexBalance >= dexAmountToStake, "Insufficient DEX balance to stake");

        _transfer(msg.sender, address(this), dexAmountToStake);

        uint256 collateralValueInEth = dexAmountToStake * dexSwapRate;

        require(address(this).balance >= collateralValueInEth, "Contract has insufficient ETH to lend");


        _loanIdCounter.increment();
        loanId = _loanIdCounter.current();
        

        uint256 actualDeadlineTimestamp = block.timestamp + requestedLoanDuration;

        Loan storage newLoan = loans[loanId];

        newLoan.deadline = actualDeadlineTimestamp;
        newLoan.amount = collateralValueInEth;
        newLoan.stakedDexAmount = dexAmountToStake;
        newLoan.periodicity = 3;
        newLoan.interest = 10;
        newLoan.termination = 10;
        newLoan.lender = address(this);
        newLoan.borrower = msg.sender;
        newLoan.isBasedNft = false;
        newLoan.nftContract = IERC721(address(0));
        newLoan.nftId = 0;
        newLoan.repaid = false;

        (bool sent, ) = msg.sender.call{value: collateralValueInEth}("");
        require(sent, "Failed to send ETH loan to borrower");

        emit loanCreated(msg.sender, loanId, collateralValueInEth, actualDeadlineTimestamp);

        return loanId;
    }

    function returnLoan(uint256 loanId) external  payable {
        require(loanId > 0, "id must be valid");
        require(msg.value > 0, "Send ETH to return loan");

        Loan storage currentLoan = loans[loanId];
        require(currentLoan.borrower != address(0));
        require(currentLoan.borrower==address(msg.sender));
        require(currentLoan.isBasedNft==false);
        require(!currentLoan.repaid, "Loan has already been repaid.");

        uint256 terminationFeeAmount = (currentLoan.amount * currentLoan.termination) / 100;
        uint256 totalAmountDue = terminationFeeAmount + currentLoan.amount;
        require(msg.value == totalAmountDue,"Incorrect ETH amount for full repayment including termination fee.");

        currentLoan.repaid = true;
        _transfer(address(this), msg.sender, currentLoan.stakedDexAmount);

        emit LoanRepaid(loanId, msg.sender, msg.value, currentLoan.stakedDexAmount);
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function setDexSwapRate(uint256 rate) external onlyOwner{
        dexSwapRate = rate;
    }

    function getDexBalance() public view returns (uint256) {
        return balanceOf(msg.sender);
    }

    function makeLoanRequestByNft(IERC721 nftContract, uint256 nftId, uint256 loanAmount, uint256 deadline) external returns (uint256 loanId){
        require(deadline > 0, "Duration must be > 0");
        require(deadline< maxLoanDuration);
        require(loanAmount > 0, "Loan amount must be greater than zero.");
        require (loanAmount <= address(this).balance,"Contract has insufficient ETH to lend.");

        require(address(nftContract)!= address(0), "NFT contract not configured" );
        require(nftContract.supportsInterface(0x80ac58cd), "Contract does not support the IERC721 interface.");
        require(nftContract.ownerOf(nftId) == msg.sender, "Caller does not own the specified NFT.");

        _loanIdCounter.increment();
        loanId = _loanIdCounter.current();
        

        uint256 actualDeadlineTimestamp = block.timestamp + deadline;

        Loan storage newLoan = loans[loanId];
        newLoan.deadline = actualDeadlineTimestamp;
        newLoan.amount = loanAmount;
        newLoan.stakedDexAmount = 0;
        newLoan.periodicity = 3;
        newLoan.interest = 10;
        newLoan.termination = 10;
        newLoan.lender = address(0);
        newLoan.borrower = msg.sender;
        newLoan.isBasedNft = true;
        newLoan.nftContract = nftContract;
        newLoan.nftId = nftId;
        newLoan.repaid = false;

        nftLoanRequestLoanId[address(nftContract)][nftId] = loanId;

        emit loanCreated(msg.sender, loanId, loanAmount, actualDeadlineTimestamp);
        return loanId;
    }

    function cancelLoanRequestByNft(IERC721 nftContract, uint256 nftId) external {
        require(address(nftContract)!=address(0), "NFT contract not configured" );
        require(nftId > 0);
        require(nftContract.ownerOf(nftId) == msg.sender, "Caller does not own the specified NFT.");

        uint256 loanId = nftLoanRequestLoanId[address(nftContract)][nftId];
        require(loanId != 0, "No active loan request found for this NFT.");

        Loan storage loanToCancel = loans[loanId];
        require(loanToCancel.lender == address(0));
        require(loanToCancel.borrower == msg.sender);

        delete loans[loanId];
        delete nftLoanRequestLoanId[address(nftContract)][nftId];
        
        emit LoanRequestCancelled(loanId, address(nftContract), nftId, msg.sender);
    }

    function loanByNft(IERC721 nftContract, uint256 nftId) external payable {
        require(address(nftContract)!=address(0), "NFT contract not configured" );
        require(nftId>0);

        uint256 loanId = nftLoanRequestLoanId[address(nftContract)][nftId];
        require(loanId != 0, "No active loan request found for this NFT.");

        Loan storage loanToFund = loans[loanId];
        require(loanToFund.lender == address(0));
        uint256 dexToStakeByLender = loanToFund.amount / dexSwapRate;

        uint256 lenderDexBalance = balanceOf(msg.sender); // balanceOf is from ERC20
        require(lenderDexBalance >= dexToStakeByLender, "Lender has insufficient DEX balance to stake.");
        _transfer(msg.sender, address(this), dexToStakeByLender);

        loanToFund.stakedDexAmount = dexToStakeByLender;
        loanToFund.lender = msg.sender;

        loanToFund.nftContract.safeTransferFrom(loanToFund.borrower, address(this), loanToFund.nftId);

        delete nftLoanRequestLoanId[address(nftContract)][nftId];

        (bool success, ) = loanToFund.borrower.call{value: loanToFund.amount}("");
        require(success, "Failed to transfer ETH to borrower.");

        // TODO: meter event bem

        //emit loanCreated(msg.sender, loanToFund.amount, loanToFund.deadline);
    }

    function checkLoan(uint256 loanId) external onlyOwner{
        /* require(_loanIdCounter.current() <= loanId, "Invalid Loan Id");
        Loan storage a =loans[loanId];
        /* if (a.deadline a.) {
            code
        } */
        // TODO: implement this */
    }
}
