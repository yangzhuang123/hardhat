// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.10;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract BoxV2 is Initializable, OwnableUpgradeable {
    uint256 private value;


    function initialize() public initializer {
        __Ownable_init(msg.sender);
        value = 0;
    }

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }

    // Increments the stored value by 1
    function increment() public {
        value += 1;
        emit ValueChanged(value);
    }
}