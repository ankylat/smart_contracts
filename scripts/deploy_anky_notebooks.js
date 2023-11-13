const { ethers, run } = require('hardhat');
const { deploymentFile } = require('../config');
const storeDeploymentData = require('../storeDeploymentData');

async function main() {
  console.log('Starting the AnkyNotebooks contract deployment...');
  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  // Grab the previously deployed AnkyAirdrop address
  const ankyAirdropAddress = '0x39D8ceF97f7Eb2AEFCB898C687291Cd28B407320';
  if (!ankyAirdropAddress) {
    console.error(
      'AnkyAirdrop address not found in deployment data. Make sure it is deployed first.'
    );
    process.exit(1);
  }

  // Deployment of AnkyDementor
  console.log('Now the AnkyNotebooks will be deployed');
  const AnkyNotebooks = await ethers.deployContract('AnkyNotebooks', [
    ankyAirdropAddress,
  ]);
  await AnkyNotebooks.waitForDeployment();
  console.log(`AnkyNotebooks deployed at: ${AnkyNotebooks.target}`);

  await run('verify:verify', {
    address: AnkyNotebooks.target,
    constructorArguments: [ankyAirdropAddress],
  });

  console.log('AnkyNotebooks contract deployed and verified!');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
