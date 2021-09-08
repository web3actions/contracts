// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import './ECDSA.sol';

contract GithubSigner {
  using ECDSA for bytes32;

  address owner;
  uint256 public fee;
  
  struct Request {
    string query;
    string nodeId;
    address consumer;
    uint256 timestamp;
  }
  mapping(uint256 => Request) requests;
  uint256 lastRequestId;

  constructor(uint256 _fee) {
    owner = msg.sender;
    fee = _fee;
    lastRequestId = 0;
  }

  function setFee(uint256 _fee) public {
    require(msg.sender == owner, 'Only owner.');
    fee = _fee;
  }

  function requestSignature(string calldata _query, string calldata _nodeId) public payable returns(uint256) {
    require(msg.value >= fee, 'Insufficiant signer payment.');
    payable(owner).transfer(msg.value);

    lastRequestId++;
    Request memory request = Request(
      _query,
      _nodeId,
      msg.sender,
      block.timestamp
    );
    requests[lastRequestId] = request;
    
    return lastRequestId;
  }

  function verifySignature(uint256 _requestId, bytes calldata _signature, bytes calldata _value) public view returns(bool) {
    require(msg.sender == requests[_requestId].consumer, 'Request can only be verified by who sent it.');

    return keccak256(abi.encodePacked(requests[_requestId].query, requests[_requestId].nodeId, _value))
      .toEthSignedMessageHash()
      .recover(_signature) == owner;
  }
}