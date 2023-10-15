const { ethers, run } = require('hardhat');
const { deploymentFile } = require('../config');
const storeDeploymentData = require('../storeDeploymentData');

async function main() {
  console.log('Starting the AnkyDementor contract deployment...');
  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  // Grab the previously deployed AnkyAirdrop address
  const ankyAirdropAddress = '0xd58c4B5cAeF1FeB906A6a49955d43B81533E1dF4';
  if (!ankyAirdropAddress) {
    console.error(
      'AnkyAirdrop address not found in deployment data. Make sure it is deployed first.'
    );
    process.exit(1);
  }

  // Deployment of AnkyDementor
  console.log('Now the AnkyDementor will be deployed');
  const AnkyDementor = await ethers.deployContract('AnkyDementor', [
    ankyAirdropAddress,
  ]);
  await AnkyDementor.waitForDeployment();
  console.log(`AnkyDementor deployed at: ${AnkyDementor.target}`);

  await run('verify:verify', {
    address: AnkyDementor.target,
    constructorArguments: [ankyAirdropAddress],
  });

  console.log('AnkyDementor contract deployed and verified!');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
