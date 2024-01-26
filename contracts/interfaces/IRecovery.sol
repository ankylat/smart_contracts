// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

interface IRecovery {
    function setRecoveryInfo(uint, address) external;
    function recoveryInfo() external view returns (uint, uint, address);
}
