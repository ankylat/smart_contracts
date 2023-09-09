const { ethers } = require('hardhat');
const { deploymentFile } = require('../config');
const storeDeploymentData = require('../storeDeploymentData');

async function deploy() {
  console.log('Starting the notebooks contracts deployment...');
  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  // Deploy ERC6551Registry
  const AnkyNotebooks = await ethers.deployContract('AnkyNotebooks', [
    '0x8e0f3DF197131baDCe2D03a3B5ED72484E44C3d3',
  ]);
  await AnkyNotebooks.waitForDeployment();
  const AnkyNotebooksAddress = AnkyNotebooks.target;
  console.log(`Deployed notebooks contract at: ${AnkyNotebooksAddress}`);
  const AnkyNotebooksDeploymentHash =
    AnkyNotebooks.deploymentTransaction().hash;
  storeDeploymentData(
    'AnkyNotebooks',
    AnkyNotebooksAddress,
    signer.address,
    AnkyNotebooksDeploymentHash,
    deploymentFile
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
