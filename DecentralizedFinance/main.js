const web3 = new Web3(window.ethereum);

// the part is related to the DecentralizedFinance smart contract
const defi_contractAddress = "0x39ed2af0A834208735Ade4a832723Ad8AB6A7630";
import { defi_abi } from "./abi_decentralized_finance.js";
const defi_contract = new web3.eth.Contract(defi_abi, defi_contractAddress);

// the part is related to the the SimpleNFT smart contract
const nft_contractAddress = "0x28eE311d5Ab665f1B629039850c53Dd3F00f3ae0";
import { nft_abi } from "./abi_nft.js";
const nft_contract = new web3.eth.Contract(nft_abi, nft_contractAddress);

let connectedAccount = null;

async function connectMetaMask() {
    if (window.ethereum) {
        try {
            const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
            connectedAccount = accounts[0]; // Armazenar a conta conectada
            console.log("Connected account:", connectedAccount);
            document.getElementById("account").innerText = "Connected: " + connectedAccount;
            window.location.href = "dashboard.html";
        } catch (error) {
            console.error("Error connecting to MetaMask:", error);
            alert("Error connecting to MetaMask. Please check your MetaMask extension.");
        }
    } else {
        alert("MetaMask not found. Please install MetaMask.");
    }
}

async function getConnectedAccount() {
    if (connectedAccount) {
        return connectedAccount;
    }
    try {
        const accounts = await window.ethereum.request({ method: "eth_accounts" }); 
        if (accounts.length > 0) {
            connectedAccount = accounts[0];
            return connectedAccount;
        } else {
            console.warn("No accounts found. Please connect MetaMask.");
            alert("Please connect your MetaMask wallet first.");
            return null;
        }
    } catch (error) {
        console.error("Error getting connected account:", error);
        alert("Error retrieving MetaMask account. Please refresh and connect.");
        return null;
    }
}

async function setRateEthToDex() {
    const rate = document.getElementById("rateInput").value;
    if (!rate || rate <= 0) {
        alert("Please enter a valid rate.");
        return;
    }
    const account = await getConnectedAccount();
    if (!account) return;

    try {
        await defi_contract.methods.setDexSwapRate(rate).send({ from: account });
        document.getElementById("rateStatus").innerText = "Rate set to " + rate;
    } catch (error) {
        console.error("Error setting rate:", error);
        alert("Error setting rate. Check console for details.");
    }
}

async function listenToLoanCreation() {
    // TODO: implement this
}

async function checkLoanStatus() {
    // TODO: implement this
}

async function buyDex() {
    const value = document.getElementById("buyEthAmount").value;
    if (!value || value <= 0) {
        alert("Enter ETH amount in wei to buy DEX.");
        return;
    }
    const account = await getConnectedAccount();
    if (!account) return;

    try {
        await defi_contract.methods.buyDex().send({ from: account, value: value });
        document.getElementById("buyStatus").innerText = `Bought DEX with ${value} wei`;
    } catch (error) {
        console.error("Error buying DEX:", error);
        alert("Error buying DEX. Check console for details.");
    }
}

async function getDex() {
    const account = await getConnectedAccount();
    if (!account) return;

    try {
        const balance = await defi_contract.methods.balanceOf(account).call();
        document.getElementById("dexBalance").innerText = "DEX Balance: " + balance;
    } catch (error) {
        console.error("Error getting DEX balance:", error);
        document.getElementById("dexBalance").innerText = "Error: Could not retrieve DEX balance. See console.";
    }
}

async function sellDex() {
    const amount = document.getElementById("sellDexAmount").value;
    if (!amount || amount <= 0) {
        alert("Enter DEX amount to sell.");
        return;
    }
    const account = await getConnectedAccount();
    if (!account) return;

    try {
        await defi_contract.methods.sellDex(amount).send({ from: account });
        document.getElementById("sellStatus").innerText = `Sold ${amount} DEX tokens`;
    } catch (error) {
        console.error("Error selling DEX:", error);
        alert("Error selling DEX. Check console for details.");
    }
}

async function loan() {
    const dexAmountToStake = document.getElementById("loanDexAmountToStake").value;
    const requestedLoanDuration = document.getElementById("loanDuration").value;

    if (!dexAmountToStake || dexAmountToStake <= 0) {
        alert("Please enter a valid DEX amount to stake.");
        return;
    }
    if (!requestedLoanDuration || requestedLoanDuration <= 0) {
        alert("Please enter a valid loan duration.");
        return;
    }

    const account = await getConnectedAccount();
    if (!account) return;

    try {
        const result = await defi_contract.methods.loan(dexAmountToStake, requestedLoanDuration).send({ from: account });
        document.getElementById("loanStatus").innerText = `Loan requested successfully! Transaction hash: ${result.transactionHash}`;
        console.log("Loan transaction result:", result);
    } catch (error) {
        console.error("Error requesting loan:", error);
        alert("Error requesting loan. Check console for details. Ensure you have enough DEX and the contract has enough ETH.");
    }
}

async function returnLoan() {
    const loanId = document.getElementById("returnLoanId").value;
    const ethAmountToReturn = document.getElementById("returnLoanEthAmount").value;

    if (!loanId || loanId <= 0) {
        alert("Please enter a valid Loan ID.");
        return;
    }
    if (!ethAmountToReturn || ethAmountToReturn <= 0) {
        alert("Please enter the ETH amount to return (in wei).");
        return;
    }

    const account = await getConnectedAccount();
    if (!account) return;

    try {
        await defi_contract.methods.returnLoan(loanId).send({ from: account, value: ethAmountToReturn });
        document.getElementById("returnLoanStatus").innerText = `Loan ID ${loanId} returned successfully!`;
    } catch (error) {
        console.error("Error returning loan:", error);
        alert("Error returning loan. Check console for details. Ensure Loan ID is correct and exact ETH amount (including fees) is sent.");
    }
}

async function makeLoanPayment() {
    const loanId = document.getElementById("paymentLoanId").value;
    const amountInEth = document.getElementById("paymentAmountEth").value;

    if (!loanId || loanId <= 0) {
        alert("Please enter a valid Loan ID.");
        return;
    }

    if (!amountInEth || amountInEth <= 0) {
        alert("Please enter a valid ETH amount.");
        return;
    }

    try {
        const account = await getConnectedAccount();
        if (!account) return;

        const amountInWei = web3.utils.toWei(amountInEth.toString(), "ether");

        await defi_contract.methods.makePayment(loanId).send({
            from: account,
            value: amountInWei
        });

        document.getElementById("status").innerText = `Payment made successfully for loan #${loanId}.`;
    } catch (error) {
        document.getElementById("status").innerText = "Error making payment. See console for details.";
        console.error("Error making payment:", error);
    }
}


async function getEthTotalBalance() {
    const account = await getConnectedAccount();
    if (!account) return;

    try {
        const contractEthBalance = await defi_contract.methods.getBalance().call({ from: account });
        document.getElementById("contractEthBalance").innerText = "Contract ETH Balance: " + web3.utils.fromWei(contractEthBalance, 'ether') + " ETH";
    } catch (error) {
        console.error("Error getting contract ETH balance:", error);
        document.getElementById("contractEthBalance").innerText = "Error: Could not retrieve balance (Owner access required or transaction error)";
    }
}

async function getRateEthToDex() {
    try {
        const rate = await defi_contract.methods.dexSwapRate().call();
        document.getElementById("exchangeRate").innerText = "Exchange rate: " + rate;
    } catch (error) {
        console.error("Failed to get ETH to DEX rate:", error);
        document.getElementById("exchangeRate").innerText = "Error: Could not retrieve Exchange Rate. See console.";
    }
}

async function getAvailableNfts() {
  try {
    const account = await getConnectedAccount();
    if (!account) return;

    const availableNftsContainer = document.getElementById("availableNftsContainer");
    availableNftsContainer.innerText = "Loading availables NFTs...";

    const nftAddress = nft_contractAddress; 
    const maxTokenId = 100; 

    const availableNfts = [];

    for (let tokenId = 1; tokenId <= maxTokenId; tokenId++) {
      try {
        const owner = await nft_contract.methods.ownerOf(tokenId).call();
        if (owner.toLowerCase() === account.toLowerCase()) {
          const isAvailable = await defi_contract.methods.isNftAvailable(nftAddress, tokenId).call({ from: account });
          if (isAvailable) {
            let tokenURI = "";
            try {
              tokenURI = await nft_contract.methods.tokenURI(tokenId).call();
            } catch (err) {
              console.warn(`Error obtaining tokenURI for token ${tokenId}:`, err);
            }
            availableNfts.push({ nftAddress, tokenId, tokenURI });
          }
        }
      } catch (err) {
        continue;
      }
    }

    if (availableNfts.length === 0) {
      availableNftsContainer.innerText = "There are no available NFTs.";
    } else {
      let html = "<ul>";
      availableNfts.forEach(({ nftAddress, tokenId, tokenURI }) => {
        html += `<li>NFT ID: ${tokenId} <br>TokenURI: ${tokenURI}</li>`;
      });
      html += "</ul>";
      availableNftsContainer.innerHTML = html;
    }

    return availableNfts;

  } catch (error) {
    console.error("Error obtaining available NFTs:", error);
    const availableNftsContainer = document.getElementById("availableNftsContainer");
    availableNftsContainer.innerText = "Error obtaining available NFTs.";
  }
}

async function getTotalBorrowedAndNotPaidBackEth() {
    // TODO: implement this
}

async function makeLoanRequestByNft() {
    const nftContractAddress = document.getElementById("nftContractAddressInput").value;
    const nftTokenId = document.getElementById("nftTokenIdInput").value;
    const loanAmount = document.getElementById("nftLoanAmountInput").value;
    const deadline = document.getElementById("nftLoanDeadlineInput").value;

    if (!nftContractAddress || !web3.utils.isAddress(nftContractAddress)) {
        alert("Please enter a valid NFT Contract Address.");
        return;
    }
    if (!nftTokenId || nftTokenId <= 0) {
        alert("Please enter a valid NFT Token ID.");
        return;
    }
    if (!loanAmount || loanAmount <= 0) {
        alert("Please enter a valid Loan Amount (in wei).");
        return;
    }
    if (!deadline || deadline <= 0) {
        alert("Please enter a valid Loan Deadline (in seconds).");
        return;
    }

    const account = await getConnectedAccount();
    if (!account) return;

    try {
        const result = await defi_contract.methods.makeLoanRequestByNft(
            nftContractAddress,
            nftTokenId,
            loanAmount,
            deadline
        ).send({ from: account });

        document.getElementById("makeNftLoanRequestStatus").innerText = `NFT Loan Request created! Transaction hash: ${result.transactionHash}`;
        console.log("NFT Loan Request transaction result:", result);
    } catch (error) {
        console.error("Error making NFT loan request:", error);
        alert("Error making NFT loan request. Check console for details. Ensure you own the NFT and the contract has enough ETH.");
    }
}

async function cancelLoanRequestByNft() {
    const cancelNftContractAddress = document.getElementById("cancelNftContractAddressInput").value;
    const cancelNftTokenId = document.getElementById("cancelNftTokenIdInput").value;

    if (!cancelNftContractAddress || !web3.utils.isAddress(cancelNftContractAddress)) {
        alert("Please enter a valid NFT Contract Address.");
        return;
    }
    if (!cancelNftTokenId || cancelNftTokenId <= 0) {
        alert("Please enter a valid NFT Token ID.");
        return;
    }

    const account = await getConnectedAccount();
    if (!account) return;

    try {
        const result = await defi_contract.methods.cancelLoanRequestByNft(
            cancelNftContractAddress,
            cancelNftTokenId
        ).send({ from: account });

        document.getElementById("cancelNftLoanRequestStatus").innerText = `NFT Loan Request for Token ID ${cancelNftTokenId} cancelled successfully! Transaction hash: ${result.transactionHash}`;
        console.log("Cancel NFT Loan Request transaction result:", result);
    } catch (error) {
        console.error("Error cancelling NFT loan request:", error);
        alert("Error cancelling NFT loan request. Check console for details. Only the NFT owner can cancel.");
    }
}

async function mintNft() {
    const tokenURI = document.getElementById("mintTokenURI").value;
    const mintPrice = 1000; // Fixed price from SimpleNFT contract in wei

    if (!tokenURI) {
        alert("Please enter a Token URI.");
        return;
    }

    const account = await getConnectedAccount();
    if (!account) return;

    try {
        const result = await nft_contract.methods.mint(tokenURI).send({ from: account, value: mintPrice });
        // Para pegar o tokenId gerado, teríamos que parsear os logs do evento ERC721.Transfer
        // Por simplicidade, exibimos o hash da transação.
        document.getElementById("mintNftStatus").innerText = `NFT minted successfully! Token ID: ${result.events.Transfer.returnValues.tokenId} | Transaction hash: ${result.transactionHash}`;
        console.log("Mint NFT transaction result:", result);
    } catch (error) {
        console.error("Error minting NFT:", error);
        alert("Error minting NFT. Check console for details. Ensure you have enough ETH (1000 wei).");
    }
}

async function approveNft() {
    const contractAddress = document.getElementById("approveNftContract").value.trim();
    const tokenId = document.getElementById("approveNftTokenId").value.trim();
    const status = document.getElementById("approveNftStatus");

    if (!web3.utils.isAddress(contractAddress) || tokenId === "") {
        status.innerText = "Please enter a valid NFT contract address and token ID.";
        return;
    }

    const account = await getConnectedAccount();
    if (!account) return;

    try {
        await nft_contract.methods.approve(defi_contractAddress, tokenId).send({ from: account });

        status.innerText = `NFT Token #${tokenId} approved successfully for DeFi contract.`;
    } catch (error) {
        console.error("Approval error:", error);
        status.innerText = "Failed to approve NFT. See console for details.";
    }
}

async function loanByNft() {
    const nftAddress = document.getElementById("fundNftContractAddressInput").value.trim();
    const tokenId = document.getElementById("fundNftTokenIdInput").value.trim();

    if (!web3.utils.isAddress(nftAddress)) {
        alert("Please enter a valid NFT Contract Address.");
        return;
    }

    if (!tokenId || isNaN(tokenId)) {
        alert("Please enter a valid Token ID.");
        return;
    }

    const account = await getConnectedAccount();
    if (!account) return;

    try {
        const loanId = await defi_contract.methods.nftLoanRequestLoanId(nftAddress, tokenId).call();

        const loan = await defi_contract.methods.loans(loanId).call();
        const amountInWei = loan.amount;

        await defi_contract.methods.loanByNft(nftAddress, tokenId).send({
            from: account,
            value: amountInWei
        });

        document.getElementById("fundNftLoanStatus").innerText = `Loan #${loanId} funded successfully with NFT ${tokenId}.`;
    } catch (error) {
        document.getElementById("fundNftLoanStatus").innerText = "Error funding loan by NFT. See console for details.";
        console.error("Error funding NFT loan:", error);
    }
}

async function checkLoan() {
    const loanId = document.getElementById("loanIdToCheckInput").value;

    if (!loanId || isNaN(loanId)) {
        alert("Please enter a valid Loan ID.");
        return;
    }

    const account = await getConnectedAccount();
    if (!account) return;

    try {
        const result = await defi_contract.methods.checkLoan(loanId).send({ from: account });

        if (result) {
            document.getElementById("checkLoanStatus").innerText = `Loan #${loanId} is in default. Collateral claimed.`;
        } else {
            document.getElementById("checkLoanStatus").innerText = `Loan #${loanId} is still up to date.`;
        }

    } catch (error) {
        document.getElementById("checkLoanStatus").innerText = "Error checking loan status. See console for details.";
        console.error("Error checking loan status:", error);
    }
}

async function getAllTokenURIs() {
    // TODO: implement this
}

// This runs when dashboard.html loads to try and get the connected account if it's already set.
// It's not critical for the `connectMetaMask` button, but for direct dashboard access.
window.addEventListener('load', async () => {
    if (window.location.pathname.endsWith("dashboard.html")) {
        await getConnectedAccount(); // Try to get the account on dashboard load
    }
});


window.connectMetaMask = connectMetaMask;
if (window.location.pathname.endsWith("dashboard.html")) {
    window.buyDex = buyDex;
    window.getDex = getDex;
    window.sellDex = sellDex;
    window.loan = loan;
    window.returnLoan = returnLoan;
    window.getEthTotalBalance = getEthTotalBalance;
    window.setRateEthToDex = setRateEthToDex;
    window.getRateEthToDex = getRateEthToDex;
    window.makeLoanRequestByNft = makeLoanRequestByNft;
    window.cancelLoanRequestByNft = cancelLoanRequestByNft;
    window.loanByNft = loanByNft;
    window.checkLoan = checkLoan;
    window.listenToLoanCreation = listenToLoanCreation;
    window.getAvailableNfts = getAvailableNfts;
    window.getTotalBorrowedAndNotPaidBackEth = getTotalBorrowedAndNotPaidBackEth;
    window.checkLoanStatus = checkLoanStatus;
    window.getAllTokenURIs = getAllTokenURIs;
    window.mintNft = mintNft; 
    window.approveNft = approveNft;
    window.makeLoanPayment = makeLoanPayment;
}