// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

abstract contract ERC677Receiver {
  function onTokenTransfer(address _sender, uint _value, bytes memory _data) virtual internal;
}