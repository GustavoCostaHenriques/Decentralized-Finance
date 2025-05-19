const web3 = new Web3(window.ethereum);

// the part is related to the DecentralizedFinance smart contract
const defi_contractAddress = "0x1Aa8C409EE2B76EDe366f393c8b85042012197C2";
import { defi_abi } from "./abi_decentralized_finance.js";
const defi_contract = new web3.eth.Contract(defi_abi, defi_contractAddress);

// the part is related to the the SimpleNFT smart contract
const nft_contractAddress = "0x424Fc67Fc53444887e6d009B18871407EB7F0D78";
import { nft_abi } from "./abi_nft.js";
const nft_contract = new web3.eth.Contract(nft_abi, nft_contractAddress);

async function connectMetaMask() {
    if (window.ethereum) {
        try {
            const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
            console.log("Connected account:", accounts[0]);
            document.getElementById("account").innerText = "Connected: " + accounts[0];
            // Redirecionar para a dashboard após conectar
            window.location.href = "dashboard.html";
        } catch (error) {
            console.error("Error connecting to MetaMask:", error);
        }
    } else {
        alert("MetaMask not found. Please install MetaMask.");
    }
}

async function setRateEthToDex() {
    const rate = document.getElementById("rateInput").value;
    if (!rate || rate <= 0) {
        alert("Please enter a valid rate.");
        return;
    }
    try {
        const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
        await defi_contract.methods.setDexSwapRate(rate).send({ from: accounts[0] });
        document.getElementById("rateStatus").innerText = "Rate set to " + rate;
    } catch (error) {
        console.error(error);
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
    try {
        const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
        await defi_contract.methods.buyDex().send({ from: accounts[0], value: value });
        document.getElementById("buyStatus").innerText = `Bought DEX with ${value} wei`;
    } catch (error) {
        console.error(error);
    }
}

async function getDex() {
    try {
        const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
        const balance = await defi_contract.methods.balanceOf(accounts[0]).call();
        document.getElementById("dexBalance").innerText = "DEX Balance: " + balance;
    } catch (error) {
        console.error(error);
    }
}

async function sellDex() {
    const amount = document.getElementById("sellDexAmount").value;
    if (!amount || amount <= 0) {
        alert("Enter DEX amount to sell.");
        return;
    }
    try {
        const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
        await defi_contract.methods.sellDex(amount).send({ from: accounts[0] });
        document.getElementById("sellStatus").innerText = `Sold ${amount} DEX tokens`;
    } catch (error) {
        console.error(error);
    }
}

async function loan() {
    // TODO: implement this
}

async function returnLoan() {
    // TODO: implement this
}

async function getEthTotalBalance() {
    // TODO: implement this
}

async function getRateEthToDex() {
    // TODO: implement this
}

async function getAvailableNfts() {
    // TODO: implement this
}

async function getTotalBorrowedAndNotPaidBackEth() {
    // TODO: implement this
}

async function makeLoanRequestByNft() {
    // TODO: implement this
}

async function cancelLoanRequestByNft() {
    // TODO: implement this
}

async function loanByNft() {
    // TODO: implement this
}

async function checkLoan() {
    // TODO: implement this
}

async function getAllTokenURIs() {
    // TODO: implement this
}

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
}