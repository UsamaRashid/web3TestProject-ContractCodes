// SPDX-License-Identifier: UNLICENSED
import "./ERC_20.sol";

pragma solidity ^0.8.3;

contract RewardToken is ERC_20 {
    address public owner;

    constructor() ERC_20("RewardToken", "RT", 50000000000) {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "MessageSender must be the contract's owner. You are not authorised"
        );
        _;
    }
}
