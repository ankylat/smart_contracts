const { ethers, run } = require('hardhat');
const { deploymentFile } = require('../config');
const storeDeploymentData = require('../storeDeploymentData');

async function main() {
  console.log('Starting the AnkyEulogias contract deployment...');
  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  // Grab the previously deployed AnkyAirdrop address
  const ankyAirdropAddress = '0x1418d2b212Bf9cE8cdEb0C07E39E4B32C7cEc147';
  if (!ankyAirdropAddress) {
    console.error(
      'AnkyAirdrop address not found in deployment data. Make sure it is deployed first.'
    );
    process.exit(1);
  }

  // Deployment of AnkyDementor
  console.log('Now the AnkyEulogias will be deployed');
  const AnkyEulogias = await ethers.deployContract('AnkyEulogias', [
    ankyAirdropAddress,
  ]);
  await AnkyEulogias.waitForDeployment();
  console.log(`AnkyEulogias deployed at: ${AnkyEulogias.target}`);

  await run('verify:verify', {
    address: AnkyEulogias.target,
    constructorArguments: [ankyAirdropAddress],
  });

  console.log('AnkyEulogias contract deployed and verified!');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
