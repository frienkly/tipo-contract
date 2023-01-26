// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Interface/ITIPOManager.sol";
import "./Interface/ITTPSManager.sol";
import "./Interface/IPriceOracle.sol";

// Contract for processing exchange request between TIPO and time points
contract TangledManager is AccessControl {
  bytes32 public constant TANGLED_MANAGER_ROLE =
    keccak256("TANGLED_MANAGER_ROLE");
  bytes32 public constant REQUEST_EXCHANGE_ROLE =
    keccak256("REQUEST_EXCHANGE_ROLE");
  bytes32 public constant UPDATE_DAILY_TIME_ROLE =
    keccak256("UPDATE_DAILY_TIME_ROLE");

  address public tipoM;
  address public ttpsM;
  address public priceOrc;

  uint256 public dailyLimitOfAmountInTime;
  uint256 private _timezone;

  struct DailyExchanged {
    uint256 dt;
    uint256 amount;
  }
  struct ExchangeUnit {
    uint64 exchangeFeeNumerator;
    uint64 exchangeFeeDenominator;
    uint128 amountInTime;
    uint256 amountOutTIPOMin;
  }

  mapping(address => DailyExchanged) private _dailyExchanged;

  event ChangeManager(address indexed prev, address indexed to);
  event UpdateDailyLimitOfAmountInTime(
    address indexed updater,
    uint256 indexed limit
  );
  event UpdateTimezone(address indexed updater, uint256 timezone);

  constructor(
    address tipoManagerAddr,
    address ttpsManagerAddr,
    address priceOrcAddr,
    uint256 limit
  ) {
    tipoM = tipoManagerAddr;
    ttpsM = ttpsManagerAddr;
    priceOrc = priceOrcAddr;

    dailyLimitOfAmountInTime = limit;
    _timezone = 6;

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function changeTIPOManager(address tipoManager)
    external
    onlyRole(TANGLED_MANAGER_ROLE)
  {
    address prev = tipoM;
    tipoM = tipoManager;
    emit ChangeManager(prev, tipoM);
  }

  function changeTTPSManager(address ttpsManager)
    external
    onlyRole(TANGLED_MANAGER_ROLE)
  {
    address prev = ttpsM;
    ttpsM = ttpsManager;
    emit ChangeManager(prev, ttpsM);
  }

  function changePriceOracle(address priceOracle)
    external
    onlyRole(TANGLED_MANAGER_ROLE)
  {
    address prev = priceOrc;
    priceOrc = priceOracle;
    emit ChangeManager(prev, priceOrc);
  }

  function updateDailyLimitOfAmountInTime(uint256 limit)
    external
    onlyRole(UPDATE_DAILY_TIME_ROLE)
  {
    dailyLimitOfAmountInTime = limit;
    emit UpdateDailyLimitOfAmountInTime(_msgSender(), dailyLimitOfAmountInTime);
  }

  // time -> TIPO called by server
  // In case of ttpsId is 0, exchange with A or A+ class watch
  function requestTimeToTIPO(
    address userAddress,
    ExchangeUnit calldata ex,
    uint256 ttpsId,
    bytes32 key
  ) external onlyRole(REQUEST_EXCHANGE_ROLE) {
    DailyExchanged storage today = _dailyExchanged[userAddress];
    uint256 dt = (block.timestamp - _timezone * 1 hours) / 1 days;
    uint256 newTodayAmount = (dt == today.dt ? today.amount : 0) +
      ex.amountInTime;
    require(
      newTodayAmount <= dailyLimitOfAmountInTime,
      "Daily exchange limit exceeded"
    );

    uint256 tipoAmount = IPriceOracle(priceOrc).calcTimeToTIPO(ex.amountInTime);
    require(tipoAmount >= ex.amountOutTIPOMin, "Don't satisfy minimum amount");

    uint256 exchangeFeeAmount = (tipoAmount * ex.exchangeFeeNumerator) /
      ex.exchangeFeeDenominator;

    if (ttpsId > 0) ITTPSManager(ttpsM).exchangeWithWatch(userAddress, ttpsId);
    ITIPOManager(tipoM).exchangeTimeToTIPO(
      userAddress,
      tipoAmount,
      exchangeFeeAmount,
      key
    );

    today.dt = dt;
    today.amount = newTodayAmount;
  }

  function getTodayExchangeAmount(address userAddress)
    external
    view
    returns (uint256)
  {
    DailyExchanged storage today = _dailyExchanged[userAddress];
    uint256 dt = (block.timestamp - _timezone * 1 hours) / 1 days;
    return (dt == today.dt ? today.amount : 0);
  }

  function updateTimezone(uint256 timezone)
    external
    onlyRole(UPDATE_DAILY_TIME_ROLE)
  {
    _timezone = timezone;

    emit UpdateTimezone(_msgSender(), timezone);
  }

  function destroy(address payable to)
    external
    payable
    onlyRole(TANGLED_MANAGER_ROLE)
  {
    require(to != address(0), "Cannot transfer to ZERO address");

    selfdestruct(to);
  }
}
