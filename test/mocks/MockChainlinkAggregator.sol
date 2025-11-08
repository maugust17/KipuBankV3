// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts@1.4.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title MockChainlinkAggregator
 * @notice Mock de Chainlink Price Feed para testing con datos configurables
 */
contract MockChainlinkAggregator is AggregatorV3Interface {
    uint8 public decimals;
    string public description;
    uint256 public version;

    int256 private _answer;
    uint80 private _roundId;
    uint256 private _updatedAt;
    uint80 private _answeredInRound;

    constructor(
        uint8 _decimals,
        string memory _description,
        uint256 _version
    ) {
        decimals = _decimals;
        description = _description;
        version = _version;

        // Valores iniciales realistas (ETH/USD ~$2000)
        _answer = 2000 * 10**8; // $2000 con 8 decimales
        _roundId = 1;
        _updatedAt = block.timestamp;
        _answeredInRound = 1;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId, _answer, _updatedAt, _updatedAt, _answeredInRound);
    }

    function getRoundData(uint80 _roundId_)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId_, _answer, _updatedAt, _updatedAt, _answeredInRound);
    }

    // Funciones de configuración para tests
    function setAnswer(int256 answer) external {
        _answer = answer;
    }

    function setRoundId(uint80 roundId) external {
        _roundId = roundId;
    }

    function setUpdatedAt(uint256 updatedAt) external {
        _updatedAt = updatedAt;
    }

    function setAnsweredInRound(uint80 answeredInRound) external {
        _answeredInRound = answeredInRound;
    }

    // Helper para configurar precio stale (antiguo)
    function makeStale(uint256 timeAgo) external {
        _updatedAt = block.timestamp - timeAgo;
    }

    // Helper para configurar round mismatched
    function makeRoundMismatch() external {
        _answeredInRound = _roundId - 1;
    }
}
