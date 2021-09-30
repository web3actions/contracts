// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import '../GithubWorkflowClient.sol';
import './Web3ActionsToken.sol';

contract Airdrop is GithubWorkflowClient {
  Web3ActionsToken public token;
  uint256 claimFee;
  mapping(string => bool) unlocked;
  mapping(string => uint256) claimed;

  constructor(address _token, string memory _workflowHash) {
    token = Web3ActionsToken(_token);
    claimFee = 10000000000000000;
    registerGithubWorkflow(msg.sender, "airdrop", _workflowHash);
  }

  function requestAirdrop(string calldata _githubUserId) payable public {
    require(msg.value >= claimFee, "ETH amount too low to pay for oracle.");
    unlocked[_githubUserId] = true;
  }

  event AirdropEvent(address to, string githubUserId, uint256 value);

  function fulfillAirdrop(
    string calldata _githubUserId,
    address _to,
    uint256 _contributionCount,
    uint256 _runId,
    bytes calldata _signature
  )
    public
    onlyGithubWorkflow(_runId, "airdrop", _signature)
  {
    require(claimed[_githubUserId] == 0, "Airdrop already claimed.");
    if (_contributionCount > 10000) {
      _contributionCount = 10000;
    }
    uint256 value = (_contributionCount * 10**18) / 10;
    // cap last airdrop if not enough tokens remain
    if (token.balanceOf(address(this)) < value) {
      value = token.balanceOf(address(this));
    }
    claimed[_githubUserId] = value;
    token.transfer(_to, value);

    emit AirdropEvent(_to, _githubUserId, value);
  }
}