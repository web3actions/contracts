// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import './GithubOracleCluster.sol';

contract GithubConsumer {
  GithubOracleCluster oracleCluster;

  function setOracleCluster(address _oracleCluster) internal {
    oracleCluster = GithubOracleCluster(_oracleCluster);
  }
}