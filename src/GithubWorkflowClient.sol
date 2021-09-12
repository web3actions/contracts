// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract GithubWorkflowClient {
  struct GithubWorkflow {
    bytes32 fileHash;
    address account;
    uint256 fee;
  }
  mapping(string => GithubWorkflow) githubWorkflows;

  struct GithubWorkflowRequest {
    address sender;
    string name;
    string githubUserId;
    bool fulfilled;
  }
  mapping(uint256 => GithubWorkflowRequest) githubWorkflowRequests;
  uint256 lastGithubWorkflowRequestId;

  event GithubWorkflowRequestEvent(uint256 requestId);

  modifier onlyWorkflow(string memory _name) {
    require(msg.sender == githubWorkflows[_name].account, "Only workflow account can change fee.");
    _;
  }

  modifier githubWorkflowResponse(uint256 _requestId) {
    require(msg.sender == githubWorkflows[githubWorkflowRequests[_requestId].name].account, "Only workflow account respond to request.");
    require(githubWorkflowRequests[_requestId].fulfilled == false, 'Request has already been fulfilled.');
    githubWorkflowRequests[_requestId].fulfilled = true;
    _;
  }

  function getGithubWorkflowRequest(uint256 _id) public view returns(
    bytes32 fileHash,
    address account,
    uint256 fee,
    address sender,
    string memory name,
    string memory githubUserId,
    bool fulfilled
  ) {
    return (
      githubWorkflows[githubWorkflowRequests[_id].name].fileHash,
      githubWorkflows[githubWorkflowRequests[_id].name].account,
      githubWorkflows[githubWorkflowRequests[_id].name].fee,
      githubWorkflowRequests[_id].sender,
      githubWorkflowRequests[_id].name,
      githubWorkflowRequests[_id].githubUserId,
      githubWorkflowRequests[_id].fulfilled
    );
  }

  function registerGithubWorkflow(address _account, string memory _name, bytes32 _hash,  uint256 _fee) internal {
    githubWorkflows[_name] = GithubWorkflow(_hash, _account, _fee);
  }

  function getGithubWorkflowFee(string calldata _name) public view returns(uint256) {
    return githubWorkflows[_name].fee;
  }

  function setGithubWorkflowFee(string calldata _name, uint256 _amount) onlyWorkflow(_name) public {
    githubWorkflows[_name].fee = _amount;
  }

  function setGithubWorkflowHash(string calldata _name, bytes32 _hash) onlyWorkflow(_name) public {
    githubWorkflows[_name].fileHash = _hash;
  }

  function githubWorkflowRequest(string memory _name, string memory _githubUserId) internal returns(uint256) {
    require(msg.value >= githubWorkflows[_name].fee, "Insufficiant oracle payment.");

    payable(githubWorkflows[_name].account).transfer(githubWorkflows[_name].fee);

    lastGithubWorkflowRequestId++;
    githubWorkflowRequests[lastGithubWorkflowRequestId] = GithubWorkflowRequest(
      _name,
      _githubUserId,
      false
    );

    emit GithubWorkflowRequestEvent(lastGithubWorkflowRequestId);
    
    return lastGithubWorkflowRequestId;
  }
}