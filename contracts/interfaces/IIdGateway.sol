// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IIdGateway {
    function price() external view returns (uint256);
    function register(address recovery, uint256 extraStorage) external payable returns (uint256 fid, uint256 overpayment);
}
