// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TIPOToken is ERC20, Ownable {
  struct TIPOMintInfo {
    address user;
    uint256 amount;
  }

  uint256 public constant INITIAL_SUPPLY = 3000000000000000000000000000; // 3B * 10^18

  constructor(TIPOMintInfo[] memory minters)
    ERC20("TIPOToken", "TIPO")
    Ownable()
  {
    uint256 sum = 0;
    for (uint256 i = 0; i < minters.length; ++i) {
      sum += minters[i].amount;
      require(
        sum <= INITIAL_SUPPLY,
        "Minting amount should not be greater than total amount"
      );
      _mint(minters[i].user, minters[i].amount);
    }

    _mint(_msgSender(), (INITIAL_SUPPLY - sum));
  }

  function destroy(address payable to) external payable onlyOwner {
    require(to != address(0), "Cannot transfer to ZERO address");

    selfdestruct(to);
  }
}
