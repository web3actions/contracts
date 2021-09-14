// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import '../GithubWorkflowClient.sol';
import './CryptoActionsToken.sol';

contract Airdrop is GithubWorkflowClient {
  CryptoActionsToken public token;

  mapping(string => uint256) claimed;
  uint256 public claimedTotal;

  constructor(address _token, string memory _workflowHash) {
    token = CryptoActionsToken(_token);
    registerGithubWorkflow(msg.sender, 'airdrop', _workflowHash, 10000000000000000);
  }

  function requestAirdrop(string calldata _githubUserId) payable public {
    githubWorkflowRequest('airdrop', _githubUserId);
  }

  event AirdropEvent(uint256 requestId, address to, string githubUserId, uint256 value);
  function fulfillAirdrop(uint256 _requestId, address _to, uint256 _contributionCount) public githubWorkflowResponse(_requestId) {
    require(claimed[githubWorkflowRequests[_requestId].githubUserId] == 0, 'Airdrop already claimed.');
    if (_contributionCount > 10000) {
      _contributionCount = 10000;
    }
    uint256 value = (_contributionCount * 10**18) / 10;
    // cap last airdrop if not enough tokens remain
    if (token.balanceOf(address(this)) < value) {
      value = token.balanceOf(address(this));
    }
    claimed[githubWorkflowRequests[_requestId].githubUserId] = value;
    token.transfer(_to, value);

    emit AirdropEvent(_requestId, _to, githubWorkflowRequests[_requestId].githubUserId, value);
  }
}