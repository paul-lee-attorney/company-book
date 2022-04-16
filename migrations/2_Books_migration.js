var IA = artifacts.require("Agreement");
var SHA = artifacts.require("ShareholdersAgreement");
var BOS = artifacts.require("BookOfShares");
var BOA = artifacts.require("BookOfDocuments");
var BOH = artifacts.require("BookOfSHA");
var BOM = artifacts.require("BookOfMotions");
var Bookeeper = artifacts.require("Bookeeper");

var LockUp = artifacts.require("LockUp");
var TagAlong =

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

        await bom.setBOH(boh.address);
        await bom.setBOS(bos.address);

        await deployer.deploy(Bookeeper, accounts[0]);
        let bookeeper = await Bookeeper.deployed();

        // await bookeeper.setBOS(bos.address);
        // await bookeeper.setBOA(boa.address);
        // await bookeeper.setBOH(boh.address);
        // await bookeeper.setBOM(bom.address);

        // await bos.setBookeeper(bookeeper.address);
        // await boa.setBookeeper(bookeeper.address);
        // await boh.setBookeeper(bookeeper.address);
        // await bom.setBookeeper(bookeeper.address);

        // await bookeeper.setBookeeper(accounts[1]);
    };