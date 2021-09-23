// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

abstract contract GithubWorkflowClient {
  address githubWorkflowSigner;

  struct GithubWorkflow {
    string fileHash;
    address account;
  }
  mapping(string => GithubWorkflow) githubWorkflows;

  modifier onlyWorkflow(uint256 _runId, string memory _name, bytes memory _signature) {
    require(msg.sender == githubWorkflows[_name].account, "Only workflow account can use this function.");

    bytes32 message = prefixed(keccak256(abi.encodePacked(githubWorkflows[_name].fileHash, _runId)));
    address recovered = recoverSigner(message, _signature);

    require(recovered == githubWorkflowSigner, "Invalid signature.");

    _;
  }

  function registerGithubWorkflow(address _account, string memory _name, string memory _hash) internal {
    githubWorkflows[_name] = GithubWorkflow(_hash, _account);
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