const Token = artifacts.require("SarafanToken");

module.exports = function(deployer) {
  deployer.deploy(Token);
};
