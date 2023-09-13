const { ethers } = require('hardhat');
const { deploymentFile } = require('../config');
const storeDeploymentData = require('../storeDeploymentData');

async function deploy() {
  console.log('Starting the Builders Notebook contracts deployment...');
  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  console.log('Now the builders notebook will be deployed');
  const BuildersNotebook = await ethers.deployContract('BuildersNotebook');
  await BuildersNotebook.waitForDeployment();
  const BuildersNotebookAddress = BuildersNotebook.target;
  console.log(
    `Deployed builders notebook contract at: ${BuildersNotebookAddress}`
  );
  const BuildersNotebooksDeploymentHash =
    BuildersNotebook.deploymentTransaction().hash;
  storeDeploymentData(
    'BuildersNotebook',
    BuildersNotebookAddress,
    signer.address,
    BuildersNotebooksDeploymentHash,
    deploymentFile
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
