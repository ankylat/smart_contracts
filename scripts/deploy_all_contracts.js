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
  const ERC1155BoundedAccount = await ethers.deployContract(
    'ERC1155BoundedAccount',
    []
  );
  await ERC1155BoundedAccount.waitForDeployment();
  console.log(
    `ERC1155BoundedAccount deployed at: ${ERC1155BoundedAccount.target}`
  );
  storeDeploymentData(
    'ERC1155BoundedAccount',
    ERC1155BoundedAccount.target,
    signer.address,
    ERC1155BoundedAccount.deploymentTransaction().hash,
    deploymentFile
  );

  // Deployment of AnkyAirdrop
  console.log('Now the AnkyAirdrop will be deployed');
  const AnkyAirdrop = await ethers.deployContract('AnkyAirdrop', [
    Registry.target,
    ERC1155BoundedAccount.target,
  ]);
  await AnkyAirdrop.waitForDeployment();
  console.log(`AnkyAirdrop deployed at: ${AnkyAirdrop.target}`);

  // Deployment of AnkyNotebooks
  console.log('Now the AnkyNotebooks will be deployed');
  const AnkyNotebooks = await ethers.deployContract('AnkyNotebooks', [
    AnkyAirdrop.target,
  ]);
  await AnkyNotebooks.waitForDeployment();
  console.log(`AnkyNotebooks deployed at: ${AnkyNotebooks.target}`);

  // Deployment of AnkyJournals
  console.log('Now the AnkyJournals will be deployed');
  const AnkyJournals = await ethers.deployContract('AnkyJournals', [
    AnkyAirdrop.target,
  ]);
  await AnkyJournals.waitForDeployment();
  console.log(`AnkyJournals deployed at: ${AnkyJournals.target}`);

  // Deployment of AnkyEulogias
  console.log('Now the AnkyEulogias will be deployed');
  const AnkyEulogias = await ethers.deployContract('AnkyEulogias', [
    AnkyAirdrop.target,
  ]);
  await AnkyEulogias.waitForDeployment();
  console.log(`AnkyEulogias deployed at: ${AnkyEulogias.target}`);

  // Deployment of AnkyDementor
  console.log('Now the AnkyDementor will be deployed');
  const AnkyDementor = await ethers.deployContract('AnkyDementor', [
    AnkyAirdrop.target,
  ]);
  await AnkyDementor.waitForDeployment();
  console.log(`AnkyDementor deployed at: ${AnkyDementor.target}`);

  // Transfer all contracts ownership to anky
  await AnkyNotebooks.transferOwnership(AnkyAirdrop.target);
  await AnkyJournals.transferOwnership(AnkyAirdrop.target);
  await AnkyEulogias.transferOwnership(AnkyAirdrop.target);
  await AnkyDementor.transferOwnership(AnkyAirdrop.target);

  await run('verify:verify', {
    address: Registry.target,
    constructorArguments: [],
  });

  await run('verify:verify', {
    address: ERC1155BoundedAccount.target,
    constructorArguments: [],
  });

  await run('verify:verify', {
    address: AnkyAirdrop.target,
    constructorArguments: [Registry.target, ERC1155BoundedAccount.target],
  });

  await run('verify:verify', {
    address: AnkyNotebooks.target,
    constructorArguments: [AnkyAirdrop.target],
  });

  await run('verify:verify', {
    address: AnkyJournals.target,
    constructorArguments: [AnkyAirdrop.target],
  });

  await run('verify:verify', {
    address: AnkyEulogias.target,
    constructorArguments: [AnkyAirdrop.target],
  });

  await run('verify:verify', {
    address: AnkyDementor.target,
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
