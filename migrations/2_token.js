const Web3ActionsToken = artifacts.require('Web3ActionsToken')
const Airdrop = artifacts.require('Airdrop')

module.exports = async function (deployer) {
  await deployer.deploy(Web3ActionsToken)
  const token = await Web3ActionsToken.deployed()
  
  await deployer.deploy(Airdrop, token.address)
  const airdrop = await Airdrop.deployed()
  
  await token.mint('0x27711f9c07230632F2EE1A21a967a9AC4729E520', '420000000000000000000000')
  await token.mint(airdrop.address, '580000000000000000000000')
}