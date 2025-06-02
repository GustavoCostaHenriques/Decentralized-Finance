# 📘 Project 2 - Group 16

## 👥 Group Members
- Henrique Vale – 58168  
- Leonardo Monteiro – 58250  
- Gustavo Henriques – 64361  

---

## 🚀 How to Run with MetaMask and Web Interface

### ✅ Prerequisites
- MetaMask installed and configured  
- [Remix IDE](https://remix.ethereum.org/)  
- Python (for serving the interface)

---

### 🛠 Step-by-Step Instructions

1. **Download and Unzip**  
   Download the project `.zip` file and extract it.

2. **Set Up Contracts in Remix**  
   - Open [Remix IDE](https://remix.ethereum.org/).
   - Create two Solidity files:
     - `decentralized_finance.sol`
     - `nft.sol`
   - Copy the contents from `project2-group16/contracts` into the respective files.

3. **Create Compiler Configuration File**  
   - Create a new file in Remix named `compiler_config.json` and paste the following content:
     ```json
     {
       "language": "Solidity",
       "settings": {
         "optimizer": {
           "enabled": true,
           "runs": 200
         },
         "viaIR": true,
         "outputSelection": {
           "*": {
             "": ["ast"],
             "*": [
               "abi", "metadata", "devdoc", "userdoc", "storageLayout",
               "evm.legacyAssembly", "evm.bytecode", "evm.deployedBytecode",
               "evm.methodIdentifiers", "evm.gasEstimates", "evm.assembly"
             ]
           }
         }
       }
     }
     ```

4. **Configure the Compiler in Remix**  
   - Select `decentralized_finance.sol`.
   - Open the **Solidity Compiler** tab.
   - Click **Advanced Configurations** → **Use configuration file** → **Change**.
   - Enter the path to `compiler_config.json`.

5. **Compile Contracts**  
   - Compile both `decentralized_finance.sol` and `nft.sol`.

6. **Update ABI Files**  
   - Copy the ABI from the compiled `decentralized_finance` contract and paste it into `abi_decentralized_finance.js`.
   - Do the same for the `nft` contract ABI.

7. **Deploy Contracts in Remix**  
   - Use the following recommended parameters for deploying `decentralized_finance`:
     - `rate: 1`
     - `periodicity: 150`
     - `interest: 10`
     - `termination: 10`  
     *(These values are simplified for easy testing.)*

8. **Update Contract Addresses in Interface Code**  
   - Copy the deployed address of `decentralized_finance` and paste it into `main.js`:
     ```js
     const defi_contractAddress = "PASTE_HERE";
     ```
   - Do the same for the NFT contract address using `nft_contractAddress`.

9. **Update `dashboard.html` with NFT Address**  
   - Locate the comment `<!--paste nft address here-->` in `dashboard.html`.
   - Paste the NFT address in all **4 indicated spots**.

10. **Start Local Web Server**  
    - Open a terminal in the project folder.
    - Run:
      ```bash
      python -m http.server 8080
      ```

11. **Access the Interface**  
    - Open your browser and go to:  
      `http://localhost:8080`  
    - You’re now ready to test the project using the web interface and MetaMask!

---

## 🧪 How to Run and Test Directly in Remix

To test the contracts in Remix without the interface:

1. Follow steps **1 through 5** and **7**.
2. Use Remix’s built-in interface to interact with the deployed contracts.

---

