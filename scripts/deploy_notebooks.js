const { ethers } = require('hardhat');

async function deploy() {
  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  const ANKY_AIRDROP_ADDRESS = '0x7e966baBF5d8f8A03e9261A5250dDDc935fB98AB';
  console.log('in here');
  const AnkyEulogias = await ethers.deployContract('AnkyEulogias', [
    '0x7e966baBF5d8f8A03e9261A5250dDDc935fB98AB',
  ]);
  console.log('the anky eulogias is: ', AnkyEulogias);

  await AnkyEulogias.waitForDeployment();
  console.log(`AnkyEulogias deployed at: ${AnkyEulogias.target}`);
  storeDeploymentData(
    'AnkyEulogias',
    AnkyEulogias.target,
    signer.address,
    AnkyEulogias.deploymentTransaction().hash,
    deploymentFile
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
