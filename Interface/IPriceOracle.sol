// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceOracle {
  event ChangeTimePrice(uint256 indexed prev, uint256 indexed to);
  event ChangeManager(address indexed prev, address indexed to);

  function calcTimeToTIPO(uint256) external view returns (uint256);

  function calcTIPOToTime(uint256) external view returns (uint256);
}
