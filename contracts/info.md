# What is ERC-6551?

A new standard for token bound accounts (TBA), which allows NFTs to have their own smart contract wallet.

This means that NFTs can hold assets. They can send other wallets assets. They can act as the owner of a wallet. Layer of identity.

What happens when you give NFTs this power?

We focus on the Registry and also the implementation accounts.

Permissionless registry. It is the single entry point. for projects wishing to utilize TBA.

createAccount (deploys once) & account.

Registry interface: What creates the TBA. Generates the address and deploys it.
Account interface: All TBA should be created via the registry. This is the instruction manual for how the TBA account should behave.




