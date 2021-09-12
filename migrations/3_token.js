const CryptoActionsToken = artifacts.require('CryptoActionsToken')
const Airdrop = artifacts.require('Airdrop')

module.exports = async function (deployer) {
  await deployer.deploy(CryptoActionsToken)
  const token = await CryptoActionsToken.deployed()
  await token.mint('0x27711f9c07230632F2EE1A21a967a9AC4729E520', '510000000000000000000000')
  
  await deployer.deploy(Airdrop, token.address, '0x0000000000000000000000000000000000000000000000000000000000000000')
  const airdrop = await Airdrop.deployed()
  await token.mint(airdrop.address, '490000000000000000000000')
}