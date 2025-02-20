import { getUserAddress, getContract } from "./utils";

export default async function userBalance() {
    const balanceDiv = document.createElement('div');
    const balance = document.createElement('p');

    try {
        const userAddress = getUserAddress();
        const contract = getContract();

        if (!contract || !userAddress) {
            throw new Error("Contract or user address not initialized");
        }

        console.log("Calling balanceOf for address:", userAddress);
        const tx = await contract.setBalance(userAddress, 100);
        // tx.wait();
        // const balanceOfUser = await contract.balanceOf(userAddress);
        // console.log("Raw balance value:", balanceOfUser);

        // balance.textContent = `Balance: ${balanceOfUser.toString()}`;
        balance.textContent = `I hate client js`
    } catch (error) {
        console.error("Error in userBalance:", error);
        balance.textContent = "Error: " + error.message;
    }

    balanceDiv.appendChild(balance);
    return balanceDiv;
}