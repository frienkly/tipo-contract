// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Interface/IPriceOracle.sol";
import "./Interface/IPancakeSwap.sol";
import "./Interface/IBUSDPrice.sol";

contract PriceOracle is AccessControl, IPriceOracle {
  bytes32 public constant ORACLE_MANAGER = keccak256("ORACLE_MANAGER");

  uint256 public timePrice;

  address public TIPO;
  address public BUSD;
  address public SWAPRouter;
  address public BUSDPriceOracle;

  constructor(
    address tipo,
    address busd,
    address swap,
    address busdPrice
  ) {
    timePrice = 0.005 * (10**18);

    TIPO = tipo;
    BUSD = busd;
    SWAPRouter = swap;
    BUSDPriceOracle = busdPrice;

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

  function getBUSDPrice() public view returns (int256, uint8) {
    return (
      IBUSDPrice(BUSDPriceOracle).latestAnswer(),
      IBUSDPrice(BUSDPriceOracle).decimals()
    );
  }

  function setTIPO(address tipo) external onlyRole(ORACLE_MANAGER) {
    require(tipo != address(0), "Invalid Address");

    address prev = TIPO;
    TIPO = tipo;

    emit ChangeManager(prev, tipo);
  }

  function setBUSD(address busd) external onlyRole(ORACLE_MANAGER) {
    require(busd != address(0), "Invalid Address");

    address prev = BUSD;
    BUSD = busd;

    emit ChangeManager(prev, busd);
  }

  function setSWAPRouter(address swap) external onlyRole(ORACLE_MANAGER) {
    require(swap != address(0), "Invalid Address");

    address prev = SWAPRouter;
    SWAPRouter = swap;

    emit ChangeManager(prev, swap);
  }

  function setBUSDPriceOracle(address busdPrice)
    external
    onlyRole(ORACLE_MANAGER)
  {
    require(busdPrice != address(0), "Invalid Address");

    address prev = BUSDPriceOracle;
    BUSDPriceOracle = busdPrice;

    emit ChangeManager(prev, busdPrice);
  }

  function calcTimeToTIPO(uint256 time) external view returns (uint256) {
    uint256 timeP = getTimePrice();
    uint256 timeValue = (time * timeP);

    uint256 busdP = uint256(IBUSDPrice(BUSDPriceOracle).latestAnswer());
    uint256 busdAmount = (timeValue *
      (10**IBUSDPrice(BUSDPriceOracle).decimals())) / busdP;

    address[] memory tokens = new address[](2);
    tokens[0] = BUSD;
    tokens[1] = TIPO;

    uint256 tipoAmount = IPancakeSwap(SWAPRouter).getAmountsOut(
      busdAmount,
      tokens
    )[1];
    return tipoAmount;
  }

  function calcTIPOToTime(uint256 tipo) external view returns (uint256) {
    address[] memory tokens = new address[](2);
    tokens[0] = TIPO;
    tokens[1] = BUSD;

    uint256 busdAmount = IPancakeSwap(SWAPRouter).getAmountsOut(tipo, tokens)[
      1
    ];
    uint256 busdP = uint256(IBUSDPrice(BUSDPriceOracle).latestAnswer());
    uint256 busdValue = (busdAmount * busdP) /
      (10**IBUSDPrice(BUSDPriceOracle).decimals());

    uint256 timeP = getTimePrice();
    uint256 timeAmount = busdValue / (timeP);
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
