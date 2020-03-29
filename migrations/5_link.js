const Token = artifacts.require("SarafanToken");
const Content = artifacts.require("SarafanContent");
const Peering = artifacts.require("SarafanPeering");

module.exports = function(deployer) {
  Token.deployed().then(function(instance) {
    instance.setPeeringContract(Peering.address);
    instance.setContentContract(Content.address);
  });
};
