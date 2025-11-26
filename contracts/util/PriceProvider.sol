// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * 价格提供者
 * @title
 * @author
 * @notice
 */
contract PriceProvider {

    mapping(address erc20 => AggregatorV3Interface priceData) priceStore;

    function putPriceData(address erc20, address v) external {
        priceStore[erc20] = AggregatorV3Interface(v);
    }

    function getPrice(address erc20) public view returns (uint256) {
        (,int256 price,,,) = priceStore[erc20].latestRoundData();
        return uint256(price);
    }
}