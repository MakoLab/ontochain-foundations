const Date = artifacts.require("./Date.sol");
const GraphParser = artifacts.require("./GraphParser.sol");
const IHash = artifacts.require("./IHash.sol");

module.exports = function(deployer) {
  deployer.deploy(Date);
  deployer.link(Date, GraphParser);
  deployer.deploy(GraphParser);
  deployer.link(GraphParser, IHash);
  deployer.deploy(IHash);
};