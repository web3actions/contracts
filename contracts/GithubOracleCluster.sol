// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract GithubOracleCluster {
  address public owner;
  uint256 public fee;

  mapping(address => bool) oracles;
  mapping(address => uint256) consumerBalances;

  struct Request {
    address consumer;
    string query;
    bytes4 fulfillFunction;
  }
  uint256 nextRequestId;
  mapping(uint256 => Request) requests;

  constructor(uint256 _fee) {
    owner = msg.sender;
    fee = _fee;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can add oracles to cluster.");
    _;
  }

  function addOracle(address _account) public onlyOwner {
    oracles[_account] = true;
  }

  function removeOracle(address _account) public onlyOwner {
    oracles[_account] = false;
  }

  function topUpConsumerBalance() public payable {
    consumerBalances[msg.sender] += msg.value;
  }

  function makeRequest(bytes4 _fulfillFunction, string calldata _query) public {
    requests[nextRequestId] = Request(msg.sender, _query, _fulfillFunction);
    nextRequestId++;
  }

  function fulfillRequest(uint256 _requestId, bytes32 _data, bytes memory _sig1, bytes memory _sig2) public returns (bool) {
    require(oracles[msg.sender], "Only registered oracles can fulfill requests.");
    require(consumerBalances[requests[_requestId].consumer] >= fee, "Consumer balance insufficiant.");

    // check signatures
    address signer1 = recoverAccountFromSignature(_data, _sig1);
    address signer2 = recoverAccountFromSignature(_data, _sig2);
    require(oracles[signer1] && oracles[signer2], "Only registered oracles can sign fulfillments.");

    // transfer fee (80% to responding oracle, 10% to each signing oracle)
    payable(msg.sender).transfer((fee * 8) / 10);
    payable(signer1).transfer(fee / 10);
    payable(signer2).transfer(fee / 10);

    // fulfill
    (bool success, ) = requests[_requestId].consumer.call(
      abi.encodeWithSelector(
        requests[_requestId].fulfillFunction,
        _requestId,
        _data
      )
    );

    return success;
  }

  function recoverAccountFromSignature(bytes32 _data, bytes memory _sig) internal pure returns(address) {
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_sig);
    return ecrecover(_data, v, r, s);
  }

  function splitSignature(bytes memory sig)
    internal
    pure
    returns (
      uint8 v,
      bytes32 r,
      bytes32 s
    )
  {
    require(sig.length == 65);

    assembly {
      // first 32 bytes, after the length prefix
      r := mload(add(sig, 32))
      // second 32 bytes
      s := mload(add(sig, 64))
      // final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(sig, 96)))
    }

    return (v, r, s);
  }
}
