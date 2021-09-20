// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import './GithubSigner.sol';

contract GithubDataReceiver {
  struct GithubDataRequest {
    address sender;
    bytes4 fulfillSelector;
    string query;
    string nodeId;
    bool fulfilled;
    uint256 signatureId;
  }
  mapping(uint256 => GithubDataRequest) githubDataRequests;
  uint256 lastGithubDataRequestId;

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

  function getGithubDataRequest(uint256 _id) public view returns(
    address sender,
    bytes4 fulfillSelector,
    string memory query,
    string memory nodeId,
    bool fulfilled,
    uint256 signatureId
  ) {
    return (
      githubDataRequests[_id].sender,
      githubDataRequests[_id].fulfillSelector,
      githubDataRequests[_id].query,
      githubDataRequests[_id].nodeId,
      githubDataRequests[_id].fulfilled,
      githubDataRequests[_id].signatureId
    );
  }

  function getGithubOracle() public view returns(address) {
    return githubOracle;
  }

  function getGithubOracleFee() public view returns(uint256) {
    return githubOracleFee;
  }

  function getGithubSignerOwner() public view returns(address) {
    return githubSigner.owner();
  }

  function getGithubSignerFee() public view returns(uint256) {
    return githubSigner.fee();
  }

  function getGithubOracleAndSignerFee() public view returns(uint256) {
    return githubOracleFee + githubSigner.fee();
  }

  modifier signedGithubOracleResponseBool(uint256 _requestId, bool _value, bytes memory _signature) {
    require(msg.sender == githubOracle, 'Only Github Oracle.');
    require(githubDataRequests[_requestId].fulfilled == false, 'Request has already been fulfilled.');
    require(githubSigner.verifySignatureBool(githubDataRequests[_requestId].signatureId, _signature, _value), 'Invalid signature.');
    githubDataRequests[_requestId].fulfilled = true;
    _;
  }

  modifier signedGithubOracleResponseAddress(uint256 _requestId, address _value, bytes memory _signature) {
    require(msg.sender == githubOracle, 'Only Github Oracle.');
    require(githubDataRequests[_requestId].fulfilled == false, 'Request has already been fulfilled.');
    require(githubSigner.verifySignatureAddress(githubDataRequests[_requestId].signatureId, _signature, _value), 'Invalid signature.');
    githubDataRequests[_requestId].fulfilled = true;
    _;
  }

  modifier signedGithubOracleResponseInt(uint256 _requestId, uint256 _value, bytes memory _signature) {
    require(msg.sender == githubOracle, 'Only Github Oracle.');
    require(githubDataRequests[_requestId].fulfilled == false, 'Request has already been fulfilled.');
    require(githubSigner.verifySignatureInt(githubDataRequests[_requestId].signatureId, _signature, _value), 'Invalid signature.');
    githubDataRequests[_requestId].fulfilled = true;
    _;
  }

  modifier signedGithubOracleResponseString(uint256 _requestId, string memory _value, bytes memory _signature) {
    require(msg.sender == githubOracle, 'Only Github Oracle.');
    require(githubDataRequests[_requestId].fulfilled == false, 'Request has already been fulfilled.');
    require(githubSigner.verifySignatureString(githubDataRequests[_requestId].signatureId, _signature, _value), 'Invalid signature.');
    githubDataRequests[_requestId].fulfilled = true;
    _;
  }

  modifier githubOracleResponse(uint256 _requestId) {
    require(msg.sender == githubOracle, 'Only Github Oracle.');
    require(githubDataRequests[_requestId].fulfilled == false, 'Request has already been fulfilled.');
    githubDataRequests[_requestId].fulfilled = true;
    _;
  }

  function githubOracleRequest(bytes4 _fulfillSelector, string memory _query, string memory _nodeId) internal returns(uint256) {
    require(msg.value >= githubOracleFee, "Insufficiant oracle payment.");

    payable(githubOracle).transfer(githubOracleFee);

    lastGithubDataRequestId++;
    githubDataRequests[lastGithubDataRequestId] = GithubDataRequest(
      msg.sender,
      _fulfillSelector,
      _query,
      _nodeId,
      false,
      0
    );

    emit GithubOracleRequestEvent(lastGithubDataRequestId, 0);
    
    return lastGithubDataRequestId;
  }

  function signedGithubOracleRequest(bytes4 _fulfillSelector, string memory _query, string memory _nodeId) internal returns(uint256) {
    require(msg.value >= githubSigner.fee() + githubOracleFee, "Insufficiant oracle and signer payment.");
    
    payable(githubOracle).transfer(githubOracleFee);

    uint256 signatureId = githubSigner.requestSignature{ value: githubSigner.fee()}(_query, _nodeId);

    lastGithubDataRequestId++;
    githubDataRequests[lastGithubDataRequestId] = GithubDataRequest(
      msg.sender,
      _fulfillSelector,
      _query,
      _nodeId,
      false,
      signatureId
    );

    emit GithubOracleRequestEvent(lastGithubDataRequestId, signatureId);
    
    return lastGithubDataRequestId;
  }
}