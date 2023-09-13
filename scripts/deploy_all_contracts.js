const { ethers, run } = require('hardhat');
const { deploymentFile } = require('../config');
const storeDeploymentData = require('../storeDeploymentData');

async function main() {
  console.log('Starting the entire contract deployment...');
  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  // Deployment of ERC6551Registry
  console.log('Now the ERC6551Registry will be deployed');
  const Registry = await ethers.deployContract('ERC6551Registry', []);
  await Registry.waitForDeployment();
  console.log(`ERC6551Registry deployed at: ${Registry.target}`);
  storeDeploymentData(
    'ERC6551Registry',
    Registry.target,
    signer.address,
    Registry.deploymentTransaction().hash,
    deploymentFile
  );

  // Deployment of ERC6551Account
  console.log('Now the ERC6551Account will be deployed');
  const ERC6551Account = await ethers.deployContract('ERC6551Account', []);
  await ERC6551Account.waitForDeployment();
  console.log(`ERC6551Account deployed at: ${ERC6551Account.target}`);
  storeDeploymentData(
    'ERC6551Account',
    ERC6551Account.target,
    signer.address,
    ERC6551Account.deploymentTransaction().hash,
    deploymentFile
  );

  // Deployment of AnkyAirdrop
  console.log('Now the AnkyAirdrop will be deployed');
  const AnkyAirdrop = await ethers.deployContract('AnkyAirdrop', [
    Registry.target,
    ERC6551Account.target,
  ]);
  await AnkyAirdrop.waitForDeployment();
  console.log(`AnkyAirdrop deployed at: ${AnkyAirdrop.target}`);
  storeDeploymentData(
    'AnkyAirdrop',
    AnkyAirdrop.target,
    signer.address,
    AnkyAirdrop.deploymentTransaction().hash,
    deploymentFile
  );

  // Deployment of AnkyTemplates
  console.log('Now the AnkyTemplates will be deployed');
  const AnkyTemplates = await ethers.deployContract('AnkyTemplates', [
    AnkyAirdrop.target,
  ]);
  await AnkyTemplates.waitForDeployment();
  console.log(`AnkyTemplates deployed at: ${AnkyTemplates.target}`);
  storeDeploymentData(
    'AnkyTemplates',
    AnkyTemplates.target,
    signer.address,
    AnkyTemplates.deploymentTransaction().hash,
    deploymentFile
  );

  // Deployment of AnkyNotebooks
  console.log('Now the AnkyNotebooks will be deployed');
  const AnkyNotebooks = await ethers.deployContract('AnkyNotebooks', [
    AnkyAirdrop.target,
    AnkyTemplates.target,
  ]);
  await AnkyNotebooks.waitForDeployment();
  console.log(`AnkyNotebooks deployed at: ${AnkyNotebooks.target}`);
  storeDeploymentData(
    'AnkyNotebooks',
    AnkyNotebooks.target,
    signer.address,
    AnkyNotebooks.deploymentTransaction().hash,
    deploymentFile
  );

  await run('verify:verify', {
    address: Registry.target,
    constructorArguments: [],
  });

  await run('verify:verify', {
    address: ERC6551Account.target,
    constructorArguments: [],
  });

  await run('verify:verify', {
    address: AnkyAirdrop.target,
    constructorArguments: [Registry.target, ERC6551Account.target],
  });

  await run('verify:verify', {
    address: AnkyTemplates.target,
    constructorArguments: [AnkyAirdrop.target],
  });

  await run('verify:verify', {
    address: AnkyNotebooks.target,
    constructorArguments: [AnkyAirdrop.target, AnkyTemplates.target],
  });

  console.log('All contracts deployed and verified!');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });