// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITIPOManager {
  event ChangeManager(address indexed prev, address indexed to);
  event SetFeeAddress(address indexed prev, address indexed to);
  event ExchangeTimeToTIPO(
    address indexed userAddress,
    bytes32 indexed key,
    uint256 amountOutTIPO,
    uint256 exchangeFeeAmount
  );
  event ExchangeTIPOToTime(
    address indexed userAddress,
    bytes32 indexed key,
    uint256 amountInTIPO,
    uint256 amountOutTime
  );
  event PayExchangeFeeAmount(
    address indexed userAddress,
    uint256 exchangeFeeAmount
  );
  event WithdrawTIPO(address indexed to, uint256 tipoAmount);

  // time -> TIPO called by manager
  function exchangeTimeToTIPO(
    address userAddr,
    uint256 amountOutTIPO,
    uint256 exchangeFeeAmount,
    bytes32 key
  ) external;

  // TIPO -> time called by user
  function exchangeTIPOToTime(
    bytes32 key,
    uint256 amountInTIPO,
    uint256 amountOutTimeMin
  ) external;
}
