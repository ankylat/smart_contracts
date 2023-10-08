// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
The mission of this smart contract is to establish the ground of a collaboration.
One that will shake the world.
Bringing the power of NFTs,
into the life of many.
Helping them battle depression,
travelling the road towards being who they are.
Developing games that will end up being fun explorations,
of you into the Ankyverse.

This is the fertile soil over which this community will be built,
using code as the foundational ground for trust to exist.

The agreement is that JP and Nyhrox will pay in total 0.08 ETH,
to the designer that will create the piece of media.
With which we will open up this partnership to the world,
on the 1st of October of 2023.

Each one of us will pay 0.04. And as soon as both amounts enter the contract,
they will be sent to the designer.
Giving birth to this partnership.
Allowing it to eternally exist on the blockchain.
*/

contract PartnershipAgreement {

    address public jp = 0xed21735DC192dC4eeAFd71b4Dc023bC53fE4DF15;
    address public nyhrox = 0x9564fe6c3C6B25F21346b6B3d281A30EecCa71Bb;
    address public designer = 0xdB5E8FB63237A2D8652F8E50F034E393a5cCAc60;  // Designer's address.

    uint256 public deadline;
    uint256 public jpDeposit = 0;
    uint256 public nyhroxDeposit = 0;

    event DepositReceived(address indexed from, uint256 amount);
    event Refunded(address indexed to, uint256 amount);

    constructor(uint256 _hoursTillDeadline) {
        deadline = block.timestamp + _hoursTillDeadline * 1 hours;
    }

    receive() external payable {
        require(msg.sender == jp || msg.sender == nyhrox, "Only JP or Nyhrox can deposit.");
        require(block.timestamp < deadline, "Deadline has passed.");
        require(msg.value == 0.04 ether, "Must deposit 0.04 ether.");

        if(msg.sender == jp) {
            jpDeposit += msg.value;
        } else if(msg.sender == nyhrox) {
            nyhroxDeposit += msg.value;
        }

        emit DepositReceived(msg.sender, msg.value);

        // Check if both parties have deposited, if so, send to the designer
        if (jpDeposit >= 0.04 ether && nyhroxDeposit >= 0.04 ether) {
            payable(designer).transfer(0.08 ether);
        }
    }

     function triggerRefunds() external {
        require(msg.sender == jp, "Only JP can trigger refunds.");
        require(block.timestamp > deadline, "Can only trigger refunds after the deadline.");

        if (jpDeposit > 0) {
            uint256 jpAmount = jpDeposit;
            jpDeposit = 0;
            payable(jp).transfer(jpAmount);
            emit Refunded(jp, jpAmount);
        }

        if (nyhroxDeposit > 0) {
            uint256 nyhroxAmount = nyhroxDeposit;
            nyhroxDeposit = 0;
            payable(nyhrox).transfer(nyhroxAmount);
            emit Refunded(nyhrox, nyhroxAmount);
        }
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }
}
