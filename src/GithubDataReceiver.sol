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

  event GithubOracleRequestEvent(uint256 requestId, uint256 signatureId);

  function setGithubOracle(address _oracle) internal {
    githubOracle = _oracle;
  }

  function setGithubSigner(address _signer) internal {
    githubSigner = GithubSigner(_signer);
  }

  function getGithubRequest(uint256 _id) public view returns(
    bytes4 fulfillSelector,
    string memory query,
    string memory nodeId,
    bool fulfilled,
    uint256 signatureId
  ) {
    return (
      githubRequests[_id].fulfillSelector,
      githubRequests[_id].query,
      githubRequests[_id].nodeId,
      githubRequests[_id].fulfilled,
      githubRequests[_id].signatureId
    );
  }

  function getGithubOracle() public view returns(address) {
    return githubOracle;
  }

  function getGithubOracleFee() public view returns(uint256) {
    return githubOracleFee;
  }

  function getGithubSigner() public view returns(address) {
    return address(githubSigner);
  }

  function getGithubSignerFee() public view returns(uint256) {
    return githubSigner.fee();
  }

  function getGithubOracleAndSignerFee() public view returns(uint256) {
    return githubOracleFee + githubSigner.fee();
  }

  modifier signedGithubOracleResponse(uint256 _requestId, bytes memory _value, bytes memory _signature) {
    require(tx.origin == githubOracle, 'Only Github Oracle.');
    require(githubRequests[_requestId].fulfilled == false, 'Request has already been fulfilled.');
    require(githubSigner.verifySignature(githubRequests[_requestId].signatureId, _signature, _value), 'Invalid signature.');
    githubRequests[_requestId].fulfilled = true;
    _;
  }

  modifier githubOracleResponse(uint256 _requestId) {
    require(tx.origin == githubOracle, 'Only Github Oracle.');
    require(githubRequests[_requestId].fulfilled == false, 'Request has already been fulfilled.');
    githubRequests[_requestId].fulfilled = true;
    _;
  }

  function githubOracleRequest(bytes4 _fulfillSelector, string memory _query, string memory _nodeId) internal returns(uint256) {
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

    emit GithubOracleRequestEvent(lastGithubRequestId, 0);
    
    return lastGithubRequestId;
  }

  function signedGithubOracleRequest(bytes4 _fulfillSelector, string memory _query, string memory _nodeId) internal returns(uint256) {
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

    emit GithubOracleRequestEvent(lastGithubRequestId, signatureId);
    
    return lastGithubRequestId;
  }

  function fulfillGithubRequestBool(uint256 _requestId, bool _value) public returns(bool) {
    (bool success,) = address(this).call(abi.encodeWithSelector(githubRequests[_requestId].fulfillSelector, _requestId, _value));
    return success;
  }

  function fulfillSignedGithubRequestBool(uint256 _requestId, bool _value, bytes memory _signature) public returns(bool) {
    (bool success,) = address(this).call(abi.encodeWithSelector(githubRequests[_requestId].fulfillSelector, _requestId, _value, _signature));
    return success;
  }
}