const { HardhatUserConfig } = require('hardhat/config');
require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();

const config = {
  solidity: {
    version: '0.8.17',
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
  },
  networks: {
    // for mainnet
    'base-mainnet': {
      url: 'https://mainnet.base.org',
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 1000000000,
    },
    // for testnet
    'base-goerli': {
      url: 'https://goerli.base.org',
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 1000000000,
    },
  },
  defaultNetwork: 'hardhat',
};

module.exports = config;
