// SPDX-License-Identifier: UNLICENSED
import "./ERC_20.sol";

pragma solidity ^0.8.3;

contract StakingToken is ERC_20 {
    address public owner;

    constructor() ERC_20("StakingToken", "ST", 100000000) {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Message sender must be the contract's owner . "
        );
        _;
    }
}
