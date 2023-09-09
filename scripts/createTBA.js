const { ethers } =  require("hardhat");

async function main() {
  const [signer] = await ethers.getSigners();
  console.log(signer.address);
  
  // change the address or mint an anky to use this one
  const ankyAirdropBaseTestnet = 
    "0x2974940b703c84D7426f4B0c71622B0DE5A49Df6";
  const deployer = await hre.ethers.provider.getSigner();
  console.log(deployer.address);
  
  const AnkyAirdrop = await hre.ethers.getContractAt(
    'AnkyAirdrop',
    ankyAirdropBaseTestnet
  );
  
  console.log('Creating TBA...');
  let tx = await AnkyAirdrop.createTBAforUsersAnky(deployer.address);
  await tx.wait();
  //console.log(tx);

  console.log('tba');
  const tba = await AnkyAirdrop.getTBA(0);
  console.log(tba);
  
  const TBA = await AnkyAirdrop.getMyAnkyAddress();
  console.log(`TBA ${TBA} to Anky of ${deployer.address}`);
}

main().catch(error => {
  console.log(error);
  process.exitCode = 1;
});
