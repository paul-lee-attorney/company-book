var LockUp = artifacts.require("LockUp");
var TagAlong = artifacts.require("TagAlong");
var AntiDilution = artifacts.require("AntiDilution");
var VotingRules = artifacts.require("VotingRules");

var Bookeeper = artifacts.require("Bookeeper");

module.exports = async function (deployer, network, accounts) {

    await deployer.deploy(LockUp);
    let lockUp = await LockUp.deployed();

    await deployer.deploy(TagAlong);
    let tagAlong = await TagAlong.deployed();

    await deployer.deploy(AntiDilution);
    let antiDilution = await AntiDilution.deployed();

    await deployer.deploy(VotingRules);
    let votingRules = await VotingRules.deployed();

    let bookeeper = await Bookeeper.deployed();

    bookeeper.addTermTemplate("0", lockUp.address);
    bookeeper.addTermTemplate("1", antiDilution.address);
    bookeeper.addTermTemplate("5", tagAlong.address);
    bookeeper.addTermTemplate("14", votingRules.address);
};