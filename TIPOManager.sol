// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./Interface/ITIPOManager.sol";
import "./Interface/IPriceOracle.sol";

// Contract for managing TIPO token
contract TIPOManager is AccessControl, Pausable, ITIPOManager {
  bytes32 public constant TIPO_MANAGER_ROLE = keccak256("TIPO_MANAGER_ROLE");
  bytes32 public constant TIPO_PAUSE_ROLE = keccak256("TIPO_PAUSE_ROLE");
  bytes32 public constant TIPO_EXCHANGE_ROLE = keccak256("TIPO_EXCHANGE_ROLE");
  bytes32 public constant TIPO_WITHDRAW_ROLE = keccak256("TIPO_WITHDRAW_ROLE");

  using SafeERC20 for IERC20;

  IERC20 public immutable tipo;
  address public priceOrc;
  address public feeAddress;

  constructor(
    IERC20 tipoAddr,
    address priceOracle,
    address feeAddr
  ) Pausable() {
    require(feeAddr != address(0), "Fee address shold not be ZERO adress");

    tipo = tipoAddr;
    priceOrc = priceOracle;
    feeAddress = feeAddr;

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function changePriceOracle(address priceOracle)
    external
    onlyRole(TIPO_MANAGER_ROLE)
  {
    address prev = priceOrc;
    priceOrc = priceOracle;
    emit ChangeManager(prev, priceOrc);
  }

  function setFeeAddress(address addr) external onlyRole(TIPO_MANAGER_ROLE) {
    require(addr != address(0), "Fee address shold not be ZERO adress");
    address prev = feeAddress;
    feeAddress = addr;

    emit SetFeeAddress(prev, feeAddress);
  }

  // time -> TIPO called by manager
  function exchangeTimeToTIPO(
    address userAddr,
    uint256 amountOutTIPO,
    uint256 exchangeFeeAmount,
    bytes32 key
  ) external onlyRole(TIPO_EXCHANGE_ROLE) {
    tipo.safeTransfer(feeAddress, exchangeFeeAmount);
    emit PayExchangeFeeAmount(userAddr, exchangeFeeAmount);

    tipo.safeTransfer(userAddr, amountOutTIPO - exchangeFeeAmount);
    emit ExchangeTimeToTIPO(userAddr, key, amountOutTIPO, exchangeFeeAmount);
  }

  // TIPO -> time called by user
  function exchangeTIPOToTime(
    bytes32 key,
    uint256 amountInTIPO,
    uint256 amountOutTimeMin
  ) external whenNotPaused {
    tipo.safeTransferFrom(_msgSender(), feeAddress, amountInTIPO);

    uint256 timeAmount = IPriceOracle(priceOrc).calcTIPOToTime(amountInTIPO);
    require(timeAmount >= amountOutTimeMin, "Don't satisfy minimum amount");

    emit ExchangeTIPOToTime(_msgSender(), key, amountInTIPO, timeAmount);
  }

  function withdrawTIPO(address to, uint256 value)
    external
    onlyRole(TIPO_WITHDRAW_ROLE)
  {
    tipo.safeTransfer(to, value);

    emit WithdrawTIPO(to, value);
  }

  function pauseTIPOManager() external onlyRole(TIPO_PAUSE_ROLE) {
    super._pause();
  }

  function unpauseTIPOManager() external onlyRole(TIPO_PAUSE_ROLE) {
    super._unpause();
  }

  function destroy(address payable to)
    external
    payable
    onlyRole(TIPO_MANAGER_ROLE)
  {
    require(to != address(0), "Cannot transfer to ZERO address");

    selfdestruct(to);
  }
}
