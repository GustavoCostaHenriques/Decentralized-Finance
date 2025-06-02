// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract DecentralizedFinance is ERC20, Ownable, ERC721Holder {
    using Counters for Counters.Counter;
    Counters.Counter private _loanIdCounter;

    uint256 public dexSwapRate;
    uint256 public maxLoanDuration = 30 days; 
    uint256 periodicity;
    uint256 interest;
    uint256 termination;
    uint256 totalStacked;

    event loanCreated(address indexed borrower, uint256 loanId, uint256 amount, uint256 deadline);
    event PaymentMade(uint256 indexed loanId, address indexed payer, uint256 amountPaid, uint256 paymentNumber);

    struct Loan {
        uint256 deadline;
        uint256 amount;
        uint256 stakedDexAmount;

        address lender;
        address borrower;
        bool isBasedNft;
        bool repaid;

        IERC721 nftContract;
        uint256 nftId;

        // Fields for periodic payment tracking
        uint256 loanStartTime;        // Timestamp when loan payments cycle began
        uint256 totalPaymentPeriods;  // Total number of interest payments expected
        uint256 paymentsMade;         // Number of periodic interest payments successfully made
        uint256 nextPaymentDueDate;   // Timestamp for the next payment
        bool paymentPassed;
    }

    mapping(uint256 => Loan) public loans;
    mapping(address => mapping(uint256 => uint256)) public nftLoanRequestLoanId;

    constructor(uint256 _rate, uint256 _periodicity, uint256 _interest, uint256 _termination) ERC20("DEX", "DEX") Ownable(msg.sender) {
        require(_rate > 0, "Rate must be > 0");
        _mint(address(this), 10**18);
        dexSwapRate = _rate;
        periodicity = _periodicity;
        interest = _interest;
        termination = _termination;
    }

    function buyDex() external payable {
        require(msg.value > 0, "Send ETH to buy DEX");
        require(dexSwapRate>0);

        uint256 dexAmount = msg.value / dexSwapRate;
        require(dexAmount > 0, "Not enough ETH to buy DEX");

        uint256 contractDexBalance = balanceOf(address(this));
        require(dexAmount <= contractDexBalance, "Not enough DEX in the contract");
        //to ensure that the contract doesnt use the stacked dex to make transactions if we didnt check this the contract would use stacked dex from a loan to make
        // a trasaction this could result in the contract not having enough dex to give to the borrower if the loan was payed
        require(dexAmount <= contractDexBalance-totalStacked);
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
        

        uint256 actualDeadlineTimestamp = block.timestamp+requestedLoanDuration;

        Loan storage newLoan = loans[loanId];
        newLoan.loanStartTime = block.timestamp;
        newLoan.deadline = actualDeadlineTimestamp;
        newLoan.amount = collateralValueInEth;
        newLoan.stakedDexAmount = dexAmountToStake;
        newLoan.lender = address(this);
        newLoan.borrower = msg.sender;
        newLoan.isBasedNft = false;
        newLoan.nftContract = IERC721(address(0));
        newLoan.nftId = 0;
        newLoan.repaid = false;

        newLoan.paymentsMade = 0;
        newLoan.totalPaymentPeriods = (actualDeadlineTimestamp - newLoan.loanStartTime) / periodicity;
        newLoan.nextPaymentDueDate = newLoan.loanStartTime + periodicity;
        newLoan.paymentPassed = false;

        totalStacked += dexAmountToStake;
        (bool sent, ) = msg.sender.call{value: collateralValueInEth}("");
        require(sent, "Failed to send ETH loan to borrower");

        emit loanCreated(msg.sender, loanId, collateralValueInEth, actualDeadlineTimestamp);

        return loanId;
    }

    function getLoanCount() external view returns (uint256) {
        return _loanIdCounter.current();
    }

    function isNftAvailable(IERC721 nftContract, uint256 nftId) public view returns (bool) {
        uint256 loanId = nftLoanRequestLoanId[address(nftContract)][nftId];
        if (loanId == 0) {
            return true; 
        }
        Loan storage l = loans[loanId];
        return l.repaid || l.lender != address(0);
    }


    function makePayment(uint256 loanId) external payable {
        require(loanId > 0, "Invalid loan ID.");
        require(msg.value > 0, "Send ETH to make payment.");

        Loan storage loanToPay = loans[loanId];

        require(loanToPay.borrower != address(0), "Loan does not exist.");
        require(loanToPay.borrower == msg.sender, "Only the borrower can make payments.");
        require(!loanToPay.repaid, "Loan has already been fully repaid.");

        require(block.timestamp < loanToPay.nextPaymentDueDate, "Payment not due yet or made too late.");

        uint256 interestDueThisPeriod = (loanToPay.amount * interest) / 100; 

        bool isFinalPaymentPeriod = (loanToPay.paymentsMade == loanToPay.totalPaymentPeriods - 1);

        if (isFinalPaymentPeriod) {
            uint256 finalPaymentAmount = loanToPay.amount + interestDueThisPeriod;
            require(msg.value == finalPaymentAmount, "Incorrect amount for final payment (principal + interest).");

            loanToPay.paymentsMade++;
            loanToPay.repaid = true;
            loanToPay.nextPaymentDueDate = type(uint256).max; 

            if (!loanToPay.isBasedNft && loanToPay.stakedDexAmount > 0) {
                _transfer(address(this), msg.sender, loanToPay.stakedDexAmount);
            }
            else if (loanToPay.isBasedNft && loanToPay.stakedDexAmount > 0)
            {
                _transfer(address(this), loanToPay.lender, loanToPay.stakedDexAmount);
                loanToPay.nftContract.safeTransferFrom(address(this), loanToPay.borrower, loanToPay.nftId);
            }
        } else if (loanToPay.paymentsMade < loanToPay.totalPaymentPeriods) { 
            require(msg.value == interestDueThisPeriod, "Incorrect amount for periodic interest payment.");
            
            loanToPay.paymentsMade++;
            loanToPay.nextPaymentDueDate += periodicity; 
        } else {
            revert("Loan payment obligations already met or invalid state.");
        }

        emit PaymentMade(loanId, msg.sender, msg.value, loanToPay.paymentsMade);
    }

    function terminateLoan(uint256 loanId) external  payable {
        require(loanId > 0, "id must be valid");
        require(msg.value > 0, "Send ETH to return loan");

        Loan storage currentLoan = loans[loanId];
        require(currentLoan.borrower != address(0));
        require(currentLoan.borrower==address(msg.sender));
        require(currentLoan.isBasedNft==false);
        require(!currentLoan.repaid, "Loan has already been repaid.");
        require(currentLoan.paymentsMade==0,"One Payment as already been made cant make full repayment");

        uint256 terminationFeeAmount = (currentLoan.amount * termination) / 100;
        uint256 totalAmountDue = terminationFeeAmount + currentLoan.amount;
        require(msg.value == totalAmountDue,"Incorrect ETH amount for full repayment including termination fee.");

        currentLoan.repaid = true;
        _transfer(address(this), msg.sender, currentLoan.stakedDexAmount);

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
        newLoan.lender = address(0);
        newLoan.borrower = msg.sender;
        newLoan.isBasedNft = true;
        newLoan.nftContract = nftContract;
        newLoan.nftId = nftId;
        newLoan.repaid = false;
        newLoan.paymentPassed = false;

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

    }

    function loanByNft(IERC721 nftContract, uint256 nftId) external payable{
        require(address(nftContract) != address(0), "NFT contract address cannot be zero.");
        require(nftId > 0, "NFT ID must be valid.");

        uint256 loanId = nftLoanRequestLoanId[address(nftContract)][nftId];
        require(loanId != 0, "No active loan request found for this NFT.");

        Loan storage loanToFund = loans[loanId];

        require(loanToFund.borrower != address(0), "Loan request data is invalid.");
        require(loanToFund.isBasedNft == true, "Loan request is not NFT-based.");
        require(loanToFund.lender == address(0), "Loan request has already been funded or is invalid.");
        require(msg.sender != loanToFund.borrower, "Borrower cannot lend to themselves.");

        require(msg.value == loanToFund.amount, "Incorrect ETH amount sent by lender to fund loan.");

        require(dexSwapRate > 0, "DEX swap rate not configured.");
        uint256 dexToStakeByLender = loanToFund.amount / dexSwapRate;
        require(dexToStakeByLender > 0, "Calculated DEX stake for lender is zero.");

        uint256 lenderDexBalance = balanceOf(msg.sender);
        require(lenderDexBalance >= dexToStakeByLender, "Lender has insufficient DEX balance to stake.");
        
        _transfer(msg.sender, address(this), dexToStakeByLender);
        
        loanToFund.stakedDexAmount = dexToStakeByLender; 


        loanToFund.nftContract.safeTransferFrom(loanToFund.borrower, address(this), loanToFund.nftId);

        loanToFund.lender = msg.sender;
        delete nftLoanRequestLoanId[address(nftContract)][nftId];

        loanToFund.loanStartTime = block.timestamp;
        loanToFund.paymentsMade = 0;

        require(periodicity > 0, "Payment periodicity not set or zero.");
        loanToFund.totalPaymentPeriods = (loanToFund.deadline - loanToFund.loanStartTime) / periodicity;
        loanToFund.nextPaymentDueDate = loanToFund.loanStartTime + periodicity;

        (bool success, ) = loanToFund.borrower.call{value: loanToFund.amount}("");
        require(success, "Failed to transfer ETH to borrower.");
    }

    function getTotalLoans() public view returns (uint256) {
        return _loanIdCounter.current();
    }

    function checkLoan(uint256 loanId) external onlyOwner  returns (bool){
        require(loanId > 0 && loanId <= _loanIdCounter.current(), "Invalid Loan ID or loan does not exist yet.");
        
        Loan storage loanToCheck = loans[loanId];
        require(!loanToCheck.paymentPassed, "Payment Failed");
        require(loanToCheck.borrower != address(0), "Loan does not exist.");
        require(!loanToCheck.repaid, "Loan is already repaid.");

        bool isPeriodicPaymentOverdue = (loanToCheck.nextPaymentDueDate != type(uint256).max &&
                                    loanToCheck.nextPaymentDueDate < block.timestamp);
        bool isFinalDeadlineOverdue = loanToCheck.deadline < block.timestamp;

        if (isPeriodicPaymentOverdue || isFinalDeadlineOverdue) {
            uint256 collateralInfo = 0;

            if (loanToCheck.isBasedNft) {
                require(loanToCheck.lender != address(0), "NFT loan was not funded.");
                loanToCheck.nftContract.safeTransferFrom(address(this), loanToCheck.lender, loanToCheck.nftId);
                collateralInfo = loanToCheck.nftId;
            } else {
                collateralInfo = loanToCheck.stakedDexAmount;
            }
            loanToCheck.paymentPassed = true;
        }
        return loanToCheck.paymentPassed;
    }
}
