// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract TestAggreagatorV3 is AggregatorV3Interface {
    uint8   public decimalsvar;
    string  public descriptionvar;
    uint256 public latestRound;
    int256  public latestAnswer;
    uint256 public latestTimestamp;

    mapping(uint256 => int256)  public getAnswer;
    mapping(uint256 => uint256) public getTimestamp;

    constructor(uint8 _decimals, string memory _description, int256 _initialAnswer) {
        decimalsvar  = _decimals;
        descriptionvar = _description;
        updateAnswer(_initialAnswer);
    }

    function updateAnswer(int256 _answer) public {
        latestAnswer   = _answer;
        latestTimestamp = block.timestamp;
        latestRound++;
        getAnswer[latestRound]   = _answer;
        getTimestamp[latestRound] = block.timestamp;
    }

    function latestRoundData() external view override returns (
        uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound
    ) {
        return (
            uint80(latestRound),
            latestAnswer,
            latestTimestamp,
            latestTimestamp,
            uint80(latestRound)
        );
    }

    function decimals() external view override returns (uint8) {
        return decimalsvar;
    }
    function description() external view override returns (string memory) {
        return descriptionvar;
    }
    function version() external pure override returns (uint256) {
        return 4;
    }

    function getRoundData(
        uint80 _roundId
    ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound){
        return (_roundId, getAnswer[_roundId], latestTimestamp, latestTimestamp, _roundId);
    }
}