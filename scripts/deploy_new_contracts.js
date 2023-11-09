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

  // Deployment of NewAnkyNotebooks
  console.log('Now the NEWAnkyNotebooks will be deployed');
  const NewAnkyNotebooks = await ethers.deployContract('NewAnkyNotebooks', [
    AnkyAirdrop.target,
  ]);
  await NewAnkyNotebooks.waitForDeployment();
  console.log(`NewAnkyNotebooks deployed at: ${NewAnkyNotebooks.target}`);
  storeDeploymentData(
    'NewAnkyNotebooks',
    NewAnkyNotebooks.target,
    signer.address,
    NewAnkyNotebooks.deploymentTransaction().hash,
    deploymentFile
  );

  // Deployment of NewAnkyJournals
  console.log('Now the NewAnkyJournals will be deployed');
  const NewAnkyJournals = await ethers.deployContract('NewAnkyJournals', [
    AnkyAirdrop.target,
  ]);
  await NewAnkyJournals.waitForDeployment();
  console.log(`NewAnkyJournals deployed at: ${NewAnkyJournals.target}`);
  storeDeploymentData(
    'NewAnkyJournals',
    NewAnkyJournals.target,
    signer.address,
    NewAnkyJournals.deploymentTransaction().hash,
    deploymentFile
  );

  // Deployment of NewAnkyEulogias
  console.log('Now the NewAnkyEulogias will be deployed');
  const NewAnkyEulogias = await ethers.deployContract('NewAnkyEulogias', [
    AnkyAirdrop.target,
  ]);
  await NewAnkyEulogias.waitForDeployment();
  console.log(`NewAnkyEulogias deployed at: ${NewAnkyEulogias.target}`);
  storeDeploymentData(
    'NewAnkyEulogias',
    NewAnkyEulogias.target,
    signer.address,
    NewAnkyEulogias.deploymentTransaction().hash,
    deploymentFile
  );

  // Deployment of NewAnkyDementor
  console.log('Now the NewAnkyDementor will be deployed');
  const NewAnkyDementor = await ethers.deployContract('NewAnkyDementor', [
    AnkyAirdrop.target,
  ]);
  await NewAnkyDementor.waitForDeployment();
  console.log(`NewAnkyDementor deployed at: ${NewAnkyDementor.target}`);
  storeDeploymentData(
    'NewAnkyDementor',
    NewAnkyDementor.target,
    signer.address,
    NewAnkyDementor.deploymentTransaction().hash,
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
    address: NewAnkyNotebooks.target,
    constructorArguments: [AnkyAirdrop.target],
  });

  await run('verify:verify', {
    address: NewAnkyJournals.target,
    constructorArguments: [AnkyAirdrop.target],
  });

  await run('verify:verify', {
    address: NewAnkyEulogias.target,
    constructorArguments: [AnkyAirdrop.target],
  });

  await run('verify:verify', {
    address: NewAnkyDementor.target,
    constructorArguments: [AnkyAirdrop.target],
  });

  console.log('All contracts deployed and verified!');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
