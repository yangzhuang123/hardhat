// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./MyAuction.sol";

contract MyAuctionV2 is MyAuction {

    string public name;

    function reinitializeV2(string memory _name) public reinitializer(2) {
        name = _name;
    }

}