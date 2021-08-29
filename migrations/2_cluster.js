const GithubOracleCluster = artifacts.require('GithubOracleCluster')

module.exports = async function (deployer) {
  // deployment steps
  await deployer.deploy(GithubOracleCluster, '10000000000000000')
  GithubOracleCluster.deployed(async cluster => {
    await cluster.addOracle('0x27711f9c07230632F2EE1A21a967a9AC4729E520')
  })
}