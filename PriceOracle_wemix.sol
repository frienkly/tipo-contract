// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Interface/IPriceOracle.sol";
import "./Interface/IWeSwap.sol";

contract PriceOracle is AccessControl, IPriceOracle {
  bytes32 public constant ORACLE_MANAGER = keccak256("ORACLE_MANAGER");

  uint256 public timePrice;
  uint8 public timeDecimals;

  address public TIPO;
  address public WemixDollar;
  address public SWAPRouter;
  // address public WemixDollarPriceOracle;

  uint256 public WemixDollarPrice; // TODO:  to be removed
  uint8 public wemixDollarDecimals; // TODO:  to be removed

  constructor(
    address tipo,
    address wemixDollar,
    address swap
  ) {
    timePrice = 0.005 * (10**18);
    timeDecimals = 18;

    TIPO = tipo;
    WemixDollar = wemixDollar;
    SWAPRouter = swap;

    // TODO: to be removed
    WemixDollarPrice = (10**8);
    wemixDollarDecimals = 8;

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function getTimePrice() public view returns (uint256) {
    return timePrice;
  }

  function setTimePrice(uint256 value) external onlyRole(ORACLE_MANAGER) {
    require(value > 0, "Invalid Price");

    uint256 prev = timePrice;
    timePrice = value;

    emit ChangeTimePrice(prev, value);
  }

  function setTimeDecimals(uint8 value) external onlyRole(ORACLE_MANAGER) {
    require(value > 0, "Invalid Decimals");

    uint8 prev = timeDecimals;
    timeDecimals = value;

    emit ChangeTimePrice(prev, value);
  }

  // TODO: to be replaced with price oracle
  function getWemixDollarPrice() public view returns (uint256, uint8) {
    return (WemixDollarPrice, wemixDollarDecimals);
  }

  // TODO: to be removed
  function setWemixDollarPrice(uint256 value)
    external
    onlyRole(ORACLE_MANAGER)
  {
    require(value > 0, "Invalid Price");

    uint256 prev = WemixDollarPrice;
    WemixDollarPrice = value;

    emit ChangeTimePrice(prev, value);
  }

  // TODO: to be removed
  function setWemixDollarDecimals(uint8 value)
    external
    onlyRole(ORACLE_MANAGER)
  {
    require(value > 0, "Invalid Decimals");

    uint8 prev = wemixDollarDecimals;
    wemixDollarDecimals = value;

    emit ChangeTimePrice(prev, value);
  }

  function setTIPO(address tipo) external onlyRole(ORACLE_MANAGER) {
    require(tipo != address(0), "Invalid Address");

    address prev = TIPO;
    TIPO = tipo;

    emit ChangeManager(prev, tipo);
  }

  function setWemixDollar(address wemixDollar)
    external
    onlyRole(ORACLE_MANAGER)
  {
    require(wemixDollar != address(0), "Invalid Address");

    address prev = WemixDollar;
    WemixDollar = wemixDollar;

    emit ChangeManager(prev, wemixDollar);
  }

  function setSWAPRouter(address swap) external onlyRole(ORACLE_MANAGER) {
    require(swap != address(0), "Invalid Address");

    address prev = SWAPRouter;
    SWAPRouter = swap;

    emit ChangeManager(prev, swap);
  }

  // TODO
  // function setWemixDollarPriceOracle(address wemixDollarPrice)
  //   external
  //   onlyRole(ORACLE_MANAGER)
  // {
  //   require(wemixDollarPrice != address(0), "Invalid Address");

  //   address prev = WemixDollarPriceOracle;
  //   WemixDollarPriceOracle = wemixDollarPrice;

  //   emit ChangeManager(prev, wemixDollarPrice);
  // }

  function calcTimeToTIPO(uint256 time) external view returns (uint256) {
    uint256 timeP = getTimePrice();
    uint256 timeValue = (time * timeP);

    uint256 wemixDollarAmount = (timeValue * (10**wemixDollarDecimals)) /
      WemixDollarPrice;

    address[] memory tokens = new address[](2);
    tokens[0] = WemixDollar;
    tokens[1] = TIPO;

    uint256 tipoAmount = IWeSwap(SWAPRouter).getAmountsOut(
      wemixDollarAmount,
      tokens
    )[1];

    return tipoAmount;
  }

  function calcTIPOToTime(uint256 tipo) external view returns (uint256) {
    address[] memory tokens = new address[](2);
    tokens[0] = TIPO;
    tokens[1] = WemixDollar;

    uint256 wemixDollarAmount = IWeSwap(SWAPRouter).getAmountsOut(tipo, tokens)[
      1
    ];
    // TODO: replace after price oracle
    // uint256 wemixDollarP = uint256(IBUSDPrice(BUSDPriceOracle).latestAnswer());
    // uint256 wemixDollarValue = (wemixDollarAmount * wemixDollarP) /
    //   (10**IBUSDPrice(BUSDPriceOracle).decimals());
    uint256 wemixDollarValue = (wemixDollarAmount * WemixDollarPrice) /
      (10**wemixDollarDecimals); //TODO:  To be removed
    uint256 timeP = getTimePrice();
    uint256 timeAmount = wemixDollarValue / (timeP);
    return timeAmount;
  }

  function destroy(address payable to)
    external
    payable
    onlyRole(ORACLE_MANAGER)
  {
    require(to != address(0), "Cannot transfer to ZERO address");

    selfdestruct(to);
  }
}
