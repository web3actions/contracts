// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract GithubSigner {
  address public owner;
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

  function getRequest(uint256 _requestId) public view returns(string memory, string memory) {
    Request memory request = requests[_requestId];
    return (request.query, request.nodeId);
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

  function verifySignatureBool(uint256 _requestId, bytes calldata _signature, bool _value) public view returns(bool) {
    require(msg.sender == requests[_requestId].consumer, 'Request can only be verified by who sent it.');

    bytes32 message = prefixed(keccak256(abi.encodePacked(requests[_requestId].query, requests[_requestId].nodeId, _value)));
    address recovered = recoverSigner(message, _signature);

    return recovered == owner;
  }

  // signature methods.
  function splitSignature(bytes memory sig)
      internal
      pure
      returns (uint8 v, bytes32 r, bytes32 s)
  {
      require(sig.length == 65);

      assembly {
          // first 32 bytes, after the length prefix.
          r := mload(add(sig, 32))
          // second 32 bytes.
          s := mload(add(sig, 64))
          // final byte (first byte of the next 32 bytes).
          v := byte(0, mload(add(sig, 96)))
      }

      return (v, r, s);
  }

  function recoverSigner(bytes32 message, bytes memory sig)
      internal
      pure
      returns (address)
  {
      (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

      return ecrecover(message, v, r, s);
  }

  // builds a prefixed hash to mimic the behavior of eth_sign.
  function prefixed(bytes32 hash) internal pure returns (bytes32) {
      return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
}