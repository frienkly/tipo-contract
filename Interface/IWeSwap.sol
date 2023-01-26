// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWeSwap {
  function getAmountsOut(uint256, address[] memory)
    external
    view
    returns (uint256[] memory);
}
