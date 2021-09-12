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

  function fulfillAirdrop(uint256 _requestId, uint256 _amount) public githubWorkflowResponse(_requestId) {
    require(claimed[githubWorkflowRequests[_requestId].githubUserId] == 0, 'Airdrop already claimed.');
    claimed[githubWorkflowRequests[_requestId].githubUserId] = _amount;
    token.transfer(githubWorkflowRequests[_requestId].sender, _amount);
  }
}