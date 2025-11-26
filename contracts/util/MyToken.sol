// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyToken", "MTK")  {
        _mint(msg.sender, 100000 * 10 ** 18);
    }

    function mintMoney(address to, uint256 v) external {
        _mint(to, v);
    }
}
