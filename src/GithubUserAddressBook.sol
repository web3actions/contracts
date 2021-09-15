// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './GithubWorkflowClient.sol';

contract GithubUserAddressBook is GithubWorkflowClient {
  mapping(string => address) githubUserAddresses;

  constructor(string memory _workflowHash) {
    registerGithubWorkflow(msg.sender, 'verify', _workflowHash, 10000000000000000);
  }

  function requestVerification(string calldata _githubUserId) payable public {
    githubWorkflowRequest('verify', _githubUserId);
  }

  event VerifyEvent(uint256 requestId);
  function verify(uint256 _requestId) public githubWorkflowResponse(_requestId) {
    githubUserAddresses[githubWorkflowRequests[_requestId].githubUserId] = githubWorkflowRequests[_requestId].sender;

    emit VerifyEvent(_requestId);
  }
}