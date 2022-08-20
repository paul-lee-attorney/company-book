const RC = artifacts.require("RegCenter");

const IA = artifacts.require("InvestmentAgreement");
const FRD = artifacts.require("FirstRefusalDeals");
const MR = artifacts.require("MockResults");
const BOA = artifacts.require("BookOfIA");
const BOD = artifacts.require("BookOfDirectors");
const SHA = artifacts.require("ShareholdersAgreement");
const BOH = artifacts.require("BookOfSHA");
const BOM = artifacts.require("BookOfMotions");
const BOO = artifacts.require("BookOfOptions");
const BOP = artifacts.require("BookOfPledges");
const BOS = artifacts.require("BookOfShares");
const BOSCal = artifacts.require("BOSCalculator");

const BOAKeeper = artifacts.require("BOAKeeper");
const BODKeeper = artifacts.require("BODKeeper");
const BOHKeeper = artifacts.require("BOHKeeper");
const BOMKeeper = artifacts.require("BOMKeeper");
const BOOKeeper = artifacts.require("BOOKeeper");
const BOPKeeper = artifacts.require("BOPKeeper");
const SHAKeeper = artifacts.require("SHAKeeper");

const GK = artifacts.require("GeneralKeeper");

const AD = artifacts.require("AntiDilution");
const DA = artifacts.require("DragAlong");
const FR = artifacts.require("FirstRefusal");
const GU = artifacts.require("GroupsUpdate");
const LU = artifacts.require("LockUp");
const OP = artifacts.require("Options");
const TA = artifacts.require("TagAlong");

module.exports = async function (callback) {

    const gk = await GK.deployed();
    console.log("GeneralKeeper: ", gk.address);

    const boaKeeper = await BOAKeeper.deployed();
    console.log("BOAKeeper: ", boaKeeper.address);

    const bom = await BOM.deployed();
    console.log("BOM: ", bom.address);

    const accounts = await web3.eth.getAccounts();
    console.log("Accts: ", accounts);

    // 获取IA
    let ia = await IA.deployed();
    console.log("IA address: ", ia.address);

    // // 卖方提交表决
    // await bookeeper.proposeMotion(ia1.address, {
    //     from: accounts[2]
    // });

    // console.log("motion of IA submitted");

    // // 股东表决
    // await bom.supportMotion(ia1.address, {
    //     from: accounts[2]
    // });

    // await bom.supportMotion(ia1.address, {
    //     from: accounts[3]
    // });

    // await bom.supportMotion(ia1.address, {
    //     from: accounts[4]
    // });

    // await bom.supportMotion(ia1.address, {
    //     from: accounts[5]
    // });

    // console.log("motion is voted");

    // // 统计表决结果
    // await bom.voteCounting(ia1.address, {
    //     from: accounts[2]
    // });

    // console.log("motion is passed");

    // // 卖方确认CP成就
    // await bookeeper.pushToCoffer("0", ia1.address, "0xa0901f1cd5c43406903d4c99948473e2d7d726ad704aaf6abf6184ea35c70f26", "0", {
    //     from: accounts[2]
    // });

    // console.log("share pushed into coffer");

    // let strKey = "peace is not free";

    // // 买方交割股权
    // await bookeeper.closeDeal("0", ia1.address, strKey, {
    //     from: accounts[8]
    // });

    // console.log("deal is closed");

    callback();
}