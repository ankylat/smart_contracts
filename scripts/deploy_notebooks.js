const { ethers } = require('hardhat');
const { deploymentFile } = require('../config');
const storeDeploymentData = require('../storeDeploymentData');

async function deploy() {
  console.log('Starting the notebooks contracts deployment...');
  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  const ANKY_AIRDROP_ADDRESS = '0x61E8537532443f49aFC73E71B014D07c13cDDca2';
  console.log('Now the templates will be deployed');
  const AnkyTemplates = await ethers.deployContract('AnkyTemplates', [
    ANKY_AIRDROP_ADDRESS,
  ]);
  await AnkyTemplates.waitForDeployment();
  const AnkyTemplatesAddress = AnkyTemplates.target;
  console.log(`Deployed templates contract at: ${AnkyTemplatesAddress}`);
  const AnkyTemplatesDeploymentHash =
    AnkyTemplates.deploymentTransaction().hash;
  storeDeploymentData(
    'AnkyTemplates',
    AnkyTemplatesAddress,
    signer.address,
    AnkyTemplatesDeploymentHash,
    deploymentFile
  );

  console.log('Now the notebooks will be deployed');
  const AnkyNotebooks = await ethers.deployContract('AnkyNotebooks', [
    ANKY_AIRDROP_ADDRESS,
    AnkyTemplatesAddress,
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
