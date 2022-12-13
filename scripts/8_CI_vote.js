const BOS = artifacts.require("BookOfShares");
const BOM = artifacts.require("BookOfMotions");
const BOA = artifacts.require("BookOfIA");
const BOH = artifacts.require("BookOfSHA");

const BOAKeeper = artifacts.require("BOAKeeper");

const GK = artifacts.require("GeneralKeeper");
const IA = artifacts.require("InvestmentAgreement");
const RC = artifacts.require("RegCenter");

const {
    getCurrentTime,
    getCurrentBN,
    advanceDays
} = require("./advanceDays");

module.exports = async function (callback) {

    const rc = await RC.deployed();

    const gk = await GK.deployed();
    console.log("GeneralKeeper address: ", gk.address);

    const boa = await BOA.deployed();
    console.log("BookOfIA: ", boa.address);

    const bom = await BOM.deployed();
    console.log("BookOfMotions: ", bom.address);

    const accounts = await web3.eth.getAccounts();
    console.log(accounts);

    let events = null;
    let cur = null;

    // ==== 设定ia ====

    let len = await boa.qtyOfDocs();
    len = len.toNumber();

    let list = await boa.docsList();

    let ia = await IA.at(list[len - 1]);
    console.log("ia address: ", ia.address);

    // ==== Vote ====

    let motionId = await web3.utils.hexToNumberString(ia.address);
    console.log("motionId: ", motionId);

    // ==== 快进7天（BlockNumber 和 timestamp）====

    console.log("start: ", await getCurrentBN(web3), await getCurrentTime(web3));
    await advanceDays(7, web3);
    console.log("end: ", await getCurrentBN(web3), await getCurrentTime(web3));


    callback();
}