var BOS = artifacts.require("BookOfShares");
var IA = artifacts.require("Agreement");
var BOA = artifacts.require("BookOfDocuments");
var SHA = artifacts.require("ShareholdersAgreement");
var BOH = artifacts.require("BookOfSHA");
var BOM = artifacts.require("BookOfMotions");
var BOO = artifacts.require("BookOfOptions");
var BOP = artifacts.require("BookOfPledges");
var BOAkeeper = artifacts.require("BOAKeeper");
var BOHKeeper = artifacts.require("BOHKeeper");
var BOMKeeper = artifacts.require("BOMKeeper");
var BOOKeeper = artifacts.require("BOOKeeper");
var BOPKeeper = artifacts.require("BOPKeeper");

var LockUp = artifacts.require("LockUp");
var TagAlong = artifacts.require("TagAlong");
var AntiDilution = artifacts.require("AntiDilution");

module.exports = async function (deployer, network, accounts) {

    await deployer.deploy(BOS, "0x38301fb0b5fcf3aaa4b97c4771bb6c75546e313b4ce7057c51a8cc6a3ace9d7e", 50, accounts[0]);
    let bos = await BOS.deployed();

    await deployer.deploy(IA);
    let ia = await IA.deployed();
    await ia.init(accounts[0], accounts[0]);

    await deployer.deploy(BOA, "BookOfAgreement", accounts[0], accounts[0]);
    let boa = await BOA.deployed();
    await boa.setTemplate(ia.address);

    await deployer.deploy(SHA);
    let sha = await SHA.deployed();
    await sha.init(accounts[0], accounts[0]);

    await deployer.deploy(BOH, "BookOfSHA", accounts[0], accounts[0]);
    let boh = await BOH.deployed();
    await boh.setTemplate(sha.address);

    await deployer.deploy(BOM, accounts[0]);
    let bom = await BOM.deployed();
    await bom.appointSubKeeper(accounts[0]);
    await bom.setBOH(boh.address);
    await bom.setBOS(bos.address);

    await deployer.deploy(BOO, accounts[0]);
    let boo = await BOO.deployed();
    await boo.appointSubKeeper(accounts[0]);
    await boo.setBOS(bos.address);

    await deployer.deploy(BOP, accounts[0]);
    let bop = await BOP.deployed();
    await bop.appointSubKeeper(accounts[0]);
    await bop.setBOS(bos.address);

    // await deployer.deploy(BOAKeeper, accounts[0]);
    // let boakeeper = await BOAKeeper.deployed();
    // await BOAkeeper.appointSubKeeper(accounts[0]);
    // await BOAkeeper.setBOA(boa.address);
    // await BOAkeeper.setBOH(boh.address);
    // await BOAkeeper.setBOM(bom.address);
    // await boakeeper.setBOS(bos.address);



    // await boa.setBOAkeeper(BOAkeeper.address);
    // await boh.setBOAkeeper(BOAkeeper.address);
    // await bom.setBOAkeeper(BOAkeeper.address);

    // await BOAkeeper.setBOAkeeper(accounts[1]);
};