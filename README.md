# Web3 Actions Contracts

## WorkflowClient

A WorkflowClient is a contract that has functions, which can only be executed with a signature from an additional signing authority. Such a signer includes the workflow file's hash and the run id in the message to sign. The Workflow Client contract needs to register that file hash and can verify the signatures.

```solidity
pragma solidity 0.8.7;

import "@web3actions/contracts/src/GithubWorkflowClient.sol";

contract MyContract is GithubWorkflowClient {
  address owner;

  constructor() {
    owner = msg.sender;
  }

  function registerWorkflow(string memory _hash) public {
    require(msg.sender == owner, "Only owner");
    registerGithubWorkflow(owner, "claim", _hash);
  }

  function claim(
    string calldata _githubUserId,
    uint256 _runId,
    bytes calldata _signature
  )
    public
    onlyGithubWorkflow(_runId, "claim", _signature)
  {
    // ...
  }
}
```