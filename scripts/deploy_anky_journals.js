const { ethers, run } = require('hardhat');
const { deploymentFile } = require('../config');
const storeDeploymentData = require('../storeDeploymentData');

async function main() {
  console.log('Starting the NewAnkyJournals contract deployment...');
  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  // Grab the previously deployed AnkyAirdrop address
  const ankyAirdropAddress = '0x1d02b6A2771a5bF55B578B14e113c6C78eed43c7';
  if (!ankyAirdropAddress) {
    console.error(
      'AnkyAirdrop address not found in deployment data. Make sure it is deployed first.'
    );
    process.exit(1);
  }

  // Deployment of NewAnkyJournals
  console.log('Now the NewAnkyJournals will be deployed');
  const NewAnkyJournals = await ethers.deployContract('NewAnkyJournals', [
    ankyAirdropAddress,
  ]);
  await NewAnkyJournals.waitForDeployment();
  console.log(`NewAnkyJournals deployed at: ${NewAnkyJournals.target}`);

  await run('verify:verify', {
    address: NewAnkyJournals.target,
    constructorArguments: [ankyAirdropAddress],
  });

  console.log('NewAnkyJournals contract deployed and verified!');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
