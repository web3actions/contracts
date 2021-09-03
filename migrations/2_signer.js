const GithubSigner = artifacts.require('GithubSigner')

module.exports = async function (deployer) {
  await deployer.deploy(GithubSigner, '10000000000000000')
}