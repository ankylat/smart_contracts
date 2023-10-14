// updateEnvFiles.js
const fs = require('fs');
const path = require('path');

const deploymentDataPath = path.join(__dirname, 'deploymentData.json');
const serverEnvPath = path.join(__dirname, '../server/.env');
const ankyLatEnvPath = path.join(__dirname, '../anky.lat/.env');

const deploymentData = JSON.parse(fs.readFileSync(deploymentDataPath));

const serverEnvContent = `
ANKY_AIRDROP_SMART_CONTRACT=${deploymentData.AnkyAirdrop.address}
ANKY_AIRDROP_CONTRACT_ADDRESS=${deploymentData.AnkyAirdrop.address}
REGISTRY_CONTRACT_ADDRESS=${deploymentData.ERC6551Registry.address}
ACCOUNT_CONTRACT_ADDRESS=${deploymentData.ERC6551Account.address}
ANKY_TEMPLATES_CONTRACT=${deploymentData.AnkyTemplates.address}
ANKY_NOTEBOOKS_CONTRACT=${deploymentData.AnkyNotebooks.address}
ANKY_JOURNALS_CONTRACT=${deploymentData.AnkyJournals.address}
ANKY_EULOGIAS_CONTRACT=${deploymentData.AnkyEulogias.address}
`;

const ankyLatEnvContent = `
NEXT_PUBLIC_ANKY_AIRDROP_SMART_CONTRACT=${deploymentData.AnkyAirdrop.address}
NEXT_PUBLIC_NOTEBOOKS_CONTRACT=${deploymentData.AnkyNotebooks.address}
NEXT_PUBLIC_TEMPLATES_CONTRACT_ADDRESS=${deploymentData.AnkyTemplates.address}
NEXT_PUBLIC_EULOGIAS_CONTRACT_ADDRESS=${deploymentData.AnkyEulogias.address}
NEXT_PUBLIC_JOURNALS_CONTRACT_ADDRESS=${deploymentData.AnkyJournals.address}
`;

fs.writeFileSync(serverEnvPath, serverEnvContent);
fs.writeFileSync(ankyLatEnvPath, ankyLatEnvContent);

console.log('Updated .env files');
