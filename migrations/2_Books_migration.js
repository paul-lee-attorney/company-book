const IA = artifacts.require("Agreement");
const SHA = artifacts.require("ShareholdersAgreement");
const BOS = artifacts.require("BookOfShares");
const BOA = artifacts.require("BookOfDocuments");
const BOH = artifacts.require("BookOfDocuments");
const BOM = artifacts.require("BookOfMotions");
const Bookkeeper = artifacts.require("Bookkeeper");

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

    await deployer.deploy(Bookkeeper, accounts[0]);
    let bookkeeper = await Bookkeeper.deployed();

    await bookkeeper.setBOS(bos.address);
    await bookkeeper.setBOA(boa.address);
    await bookkeeper.setBOH(boh.address);
    await bookkeeper.setBOM(bom.address);

    await bos.setBookkeeper(bookkeeper.address);
    await boa.setBookkeeper(bookkeeper.address);
    await boh.setBookkeeper(bookkeeper.address);
    await bom.setBookkeeper(bookkeeper.address);

    await bookkeeper.setBookkeeper(accounts[1]);
};