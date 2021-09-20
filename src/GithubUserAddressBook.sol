// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './GithubDataReceiver.sol';

contract GithubUserAddressBook is GithubDataReceiver {
  mapping(string => address) githubUserAddresses;
  mapping(address => string) githubUserIds;
  mapping(uint256 => string) verificationRequests;

  constructor(address _oracle, address _signer, uint256 _fee) {
    githubOracleFee = _fee;
    setGithubOracle(_oracle);
    setGithubSigner(_signer);
  }

  function requestAddressVerification(string calldata _githubUserId) payable public {
    uint256 requestId = signedGithubOracleRequest(
      this.verifyAddress.selector,
      'User { gists(last: 1) { nodes { files(limit: 1) { text } } } }',
      _githubUserId
    );

    verificationRequests[requestId] = _githubUserId;
  }

  event VerifyAddressEvent(uint256 requestId, string githubUserId, address account);
  function verifyAddress(uint256 _requestId, address _value, bytes memory _signature)
    public
    signedGithubOracleResponseAddress(_requestId, _value, _signature)
  {
    require(_value == githubDataRequests[_requestId].sender, "Address does not match the requested one.");
    githubUserAddresses[verificationRequests[_requestId]] = _value;
    emit VerifyAddressEvent(_requestId, verificationRequests[_requestId], _value);
  }

  function get(string calldata _githubUserId) public view returns(address payable) {
    return payable(githubUserAddresses[_githubUserId]);
  }

  function getId(address _address) public view returns(string memory) {
    return githubUserIds[_address];
  }
}