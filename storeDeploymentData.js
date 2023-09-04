const fs = require('fs');
function storeDeploymentData(
  contractName,
  contractAddress,
  deployer,
  deploymentHash,
  deploymentFile
) {
  const deploymentData = {
    [contractName]: {
      address: contractAddress,
      deployer: deployer,
      deploymentHash: deploymentHash,
    },
  };

  if (!fs.existsSync(deploymentFile)) {
    fs.closeSync(fs.openSync(deploymentFile, 'w'));
  }

  const file = fs.readFileSync(deploymentFile);

  if (file.length == 0) {
    fs.writeFileSync(deploymentFile, JSON.stringify([deploymentData]));
    console.log(`Saved deployment data to a new file: ${deploymentFile}`);
  } else {
    const json = JSON.parse(file.toString());
    json.push(deploymentData);
    console.log(json);
    fs.writeFileSync(deploymentFile, JSON.stringify(json));
    console.log(`Deployment data saved to: ${deploymentFile}`);
  }
}

module.exports = storeDeploymentData;
