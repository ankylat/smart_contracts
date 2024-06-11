const { ethers } = require('hardhat');

async function deploy() {
  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  console.log('in here');
  const BadgelessContract = await ethers.deployContract('Badgeless', [
  ]);
  console.log('the BadgelessContract is: ', BadgelessContract);

  await BadgelessContract.waitForDeployment();
  console.log(`BadgelessContract deployed at: ${BadgelessContract.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
