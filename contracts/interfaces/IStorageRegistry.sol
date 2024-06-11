// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IStorageRegistry {
    function unitPrice() external view returns (uint256);
    function rent(uint256 fid, uint256 units) external payable returns (uint256 overpayment);
}
