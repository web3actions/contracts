// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import './GithubSigner.sol';

contract GithubDataReceiver {
  struct GithubRequest {
    bytes4 fulfillSelector;
    string query;
    string nodeId;
    bool fulfilled;
    uint256 signatureId;
  }
  mapping(uint256 => GithubRequest) githubRequests;
  uint256 lastGithubRequestId;

  uint256 public githubOracleFee;
  address githubOracle;
  GithubSigner githubSigner;

  function setGithubOracle(address _oracle) internal {
    githubOracle = _oracle;
  }

  function setGithubSigner(address _signer) internal {
    githubSigner = GithubSigner(_signer);
  }

  function getGithubOracleFee() public view returns(uint256) {
    return githubOracleFee;
  }

  function getGithubSignerFee() public view returns(uint256) {
    return githubSigner.fee();
  }

  modifier signedGithubOracleResponse(uint256 _requestId, string memory _value, bytes memory _signature) {
    require(msg.sender == githubOracle, 'Only Github Oracle.');
    require(githubRequests[_requestId].fulfilled == false, 'Request has already been fulfilled.');
    require(githubSigner.verifySignature(githubRequests[_requestId].signatureId, _signature, _value), 'Invalid signature.');
    githubRequests[_requestId].fulfilled = true;
    _;
  }

  modifier githubOracleResponse(uint256 _requestId) {
    require(msg.sender == githubOracle, 'Only Github Oracle.');
    require(githubRequests[_requestId].fulfilled == false, 'Request has already been fulfilled.');
    githubRequests[_requestId].fulfilled = true;
    _;
  }

  function githubOracleRequest(bytes4 _fulfillSelector, string calldata _query, string calldata _nodeId) internal returns(uint256) {
    require(msg.value >= githubOracleFee, "Insufficiant oracle payment.");

    payable(githubOracle).transfer(githubOracleFee);

    lastGithubRequestId++;
    githubRequests[lastGithubRequestId] = GithubRequest(
      _fulfillSelector,
      _query,
      _nodeId,
      false,
      0
    );
    
    return lastGithubRequestId;
  }

  function signedGithubOracleRequest(bytes4 _fulfillSelector, string calldata _query, string calldata _nodeId) internal returns(uint256) {
    require(msg.value >= githubSigner.fee() + githubOracleFee, "Insufficiant oracle and signer payment.");
    
    payable(githubOracle).transfer(githubOracleFee);

    uint256 signatureId = githubSigner.requestSignature{ value: githubSigner.fee()}(_query, _nodeId);

    lastGithubRequestId++;
    githubRequests[lastGithubRequestId] = GithubRequest(
      _fulfillSelector,
      _query,
      _nodeId,
      false,
      signatureId
    );
    
    return lastGithubRequestId;
  }
}