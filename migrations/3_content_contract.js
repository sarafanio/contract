const Token = artifacts.require("SarafanToken");
const Content = artifacts.require("SarafanContent");

module.exports = function(deployer) {
  deployer.deploy(Content, Token.address)
};
