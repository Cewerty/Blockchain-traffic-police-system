import hre from 'hardhat';

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    
    const contractFabric = await hre.ethers.getContractFactory("TrafficPoliceSystem", deployer);

    const contract = await contractFabric.deploy();

    contract.waitForDeployment();

    const contractAddress = await contract.getAddress();

    const deployerAddress = await deployer.getAddress();

    await contract.setBalance(deployerAddress, 1000000020);

    console.log("Contract", contractAddress);
}

main().then(()=> process.exit(0)).catch(()=> process.exit(1));