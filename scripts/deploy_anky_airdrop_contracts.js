const { ethers } = require('hardhat');
const { deploymentFile } = require('../config');
const storeDeploymentData = require('../storeDeploymentData');

async function deploy() {
  console.log('Starting contract deployment...');
  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  // Deploy ERC6551Registry
  const Registry = await ethers.deployContract('ERC6551Registry');
  await Registry.waitForDeployment();
  const RegistryAddress = Registry.target;
  console.log(`Deployed registry contract at: ${RegistryAddress}`);
  const RegistryDeploymentHash = Registry.deploymentTransaction().hash;
  storeDeploymentData(
    'ERC6551Registry',
    RegistryAddress,
    signer.address,
    RegistryDeploymentHash,
    deploymentFile
  );

  // Deploy ERC6551Account
  const ERC6551Account = await ethers.deployContract('ERC6551Account');
  await ERC6551Account.waitForDeployment();
  const ERC6551AccountAddress = ERC6551Account.target;
  const ERC6551AccountDeploymentHash =
    ERC6551Account.deploymentTransaction().hash;
  console.log(`Token bound account deployed at: ${ERC6551Account.target}`);
  storeDeploymentData(
    'ERC6551Account',
    ERC6551AccountAddress,
    signer.address,
    ERC6551AccountDeploymentHash,
    deploymentFile
  );

  // Deploy AnkyAirdrop with the ERC6551Account's address as the implementationAddress
  const AnkyAirdrop = await ethers.deployContract('AnkyAirdrop', [
    RegistryAddress,
    ERC6551AccountAddress,
  ]);
  await AnkyAirdrop.waitForDeployment();
  const AnkyAidropAddress = AnkyAirdrop.target;
  console.log(`AnkyAirdrop deployed to: ${AnkyAidropAddress}`);
  const AnkyAidropDeploymentHash = AnkyAirdrop.deploymentTransaction().hash;
  storeDeploymentData(
    'AnkyAirdrop',
    AnkyAidropAddress,
    signer.address,
    AnkyAidropDeploymentHash,
    deploymentFile
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
