const BOS = artifacts.require("BookOfShares");
const BOM = artifacts.require("BookOfMotions");
const BOA = artifacts.require("BookOfIA");
const BOH = artifacts.require("BookOfSHA");

const BOAKeeper = artifacts.require("BOAKeeper");

const GK = artifacts.require("GeneralKeeper");
const IA = artifacts.require("InvestmentAgreement");
const RC = artifacts.require("RegCenter");

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

    // ==== 提交IA ====

    await gk.proposeIA(ia.address, {
        from: accounts[2]
    });

    events = await boa.getPastEvents("UpdateStateOfDoc");
    console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);

    // ==== Vote ====

    let motionId = await web3.utils.hexToNumberString(ia.address);
    console.log("motionId: ", motionId);

    // // ==== 快进7天（BlockNumber 和 timestamp）====

    let bn = await web3.eth.getBlockNumber();
    console.log("current BN: ", bn);

    cur = await web3.eth.getBlock("latest");
    console.log("current timestamp: ", cur.timestamp);

    await web3.currentProvider.send({
        method: "evm_increaseTime",
        params: [86400 * 7]
    }, () => {});

    await web3.currentProvider.send({
        method: "evm_mine",
        params: [{
            blocks: 240 * 7
        }]
    }, () => {});

    bn = await web3.eth.getBlockNumber();
    console.log("current BN: ", bn);

    cur = await web3.eth.getBlock("latest");
    console.log("current timestamp: ", cur.timestamp);

    callback();
}