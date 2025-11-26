// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "./MyAuctionFactory.sol";

contract MyAuctionFactoryV2 is MyAuctionFactory {

    string public name;

    function initializeV2(string memory _name) public reinitializer(2) {
        name = _name;
    }

}