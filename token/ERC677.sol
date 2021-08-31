// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import { ERC20 } from "./ERC20.sol";

contract ERC677 is ERC20 {
  function transferAndCall(address to, uint value, bytes data) returns (bool success);

  event Transfer(address indexed from, address indexed to, uint value, bytes data);
}