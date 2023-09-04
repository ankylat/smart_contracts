const { ethers } = require('hardhat');

async function main() {
  console.log('Starting contract deployment...');

  // Deploy ERC6551Account
  const erc6551Account = await ethers.deployContract('ERC6551Account');
  await erc6551Account.waitForDeployment();
  console.log('ERC6551Account deployed to:', erc6551Account.target);

  // Deploy ERC6551Registry
  const erc6551Registry = await ethers.deployContract('ERC6551Registry');
  await erc6551Registry.waitForDeployment();
  console.log('ERC6551Registry deployed to:', erc6551Registry.target);

  // Deploy AnkyAirdrop with the ERC6551Account's address as the implementationAddress
  const ankyAirdrop = await ethers.deployContract('AnkyAirdrop', [
    erc6551Registry.target,
    erc6551Account.target,
  ]);
  await ankyAirdrop.waitForDeployment();
  console.log('AnkyAirdrop deployed to:', ankyAirdrop.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
