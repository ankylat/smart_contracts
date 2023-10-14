// storeDeploymentData.js
const fs = require('fs');
const path = require('path');
const deploymentFilePath = path.join(__dirname, 'deploymentData.json');

function storeDeploymentData(
  contractName,
  address,
  deployer,
  deploymentHash,
  deploymentFile
) {
  let existingData = {};
  if (fs.existsSync(deploymentFilePath)) {
    const fileContent = fs.readFileSync(deploymentFilePath, 'utf8');
    if (fileContent) {
      existingData = JSON.parse(fileContent);
    }
  }
  const updatedData = {
    ...existingData,
    [contractName]: {
      address,
      deployer,
      deploymentHash,
    },
  };
  fs.writeFileSync(deploymentFilePath, JSON.stringify(updatedData, null, 2));
}

module.exports = storeDeploymentData;
