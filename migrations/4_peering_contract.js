const Token = artifacts.require("SarafanToken");
const Peering = artifacts.require("SarafanPeering");

module.exports = function(deployer) {
  deployer.deploy(Peering, Token.address)
};
