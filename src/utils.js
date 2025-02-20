import { BrowserProvider, Contract } from 'ethers';
import contractJSON from '../artifacts/contracts/dps.sol/TrafficPoliceSystem.json' with { type: 'json' };

let contractABI = contractJSON.abi;
let contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
let contract;
let userAddress;
let provider;
let signer;

export async function init() {
    if (!window.ethereum) {
        alert("Install Metamask!");
        return;
    }

    try {
        provider = new BrowserProvider(window.ethereum);
        const network = await provider.getNetwork();
        console.log("Network:", network);

        // Проверка chainId, если необходимо
        if (network.chainId !== 31337n) { // Пример для локальной сети Hardhat
            alert("Connect to the correct network!");
            return;
        }

        signer = await provider.getSigner();
        userAddress = await signer.getAddress();
        console.log("User Address:", userAddress);

        contract = new Contract(contractAddress, contractABI, signer);
        console.log("Contract Address:", await contract.getAddress()); // Проверка адреса контракта
    } catch (error) {
        console.error("Error during initialization:", error);
    }
}

export function getContract() {
    return contract;
}

export function getUserAddress() {
    return userAddress;
}