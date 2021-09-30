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
    address _to,
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

```yaml
# workflow file
steps:
  - name: Claim
    uses: web3actions/tx@bc0119599bd6377e4b4070722d77feb6f07986f8
    with:
      network: kovan
      infura-key: ${{ secrets.INFURA_KEY }}
      wallet-key: ${{ secrets.WALLET_KEY }}
      contract: "0x123456..."
      function: "claim(string,address,uint256,bytes)" # ...,uint256,bytes for run id and signature
      inputs: '["${{ github.event.issue.user.node_id }}", "${{ fromJSON(github.event.issue.body).to }}"]'
      signer: web3actions/signer # signs this workflow's file hash and run id
      github-token: ${{ secrets.PAT }}
      gas-limit: 100000
```