const BOS = artifacts.require("BookOfShares");
const BOM = artifacts.require("BookOfMotions");
const BOA = artifacts.require("BookOfIA");
const BOH = artifacts.require("BookOfSHA");

const BOAKeeper = artifacts.require("BOAKeeper");

const GK = artifacts.require("GeneralKeeper");
const IA = artifacts.require("InvestmentAgreement");
const RC = artifacts.require("RegCenter");

module.exports = async function (callback) {

    const gk = await GK.deployed();
    console.log("GeneralKeeper address: ", gk.address);

    const boa = await BOA.deployed();
    console.log("BookOfIA: ", boa.address);

    const bom = await BOM.deployed();
    console.log("BookOfMotion: ", bom.address);

    const accounts = await web3.eth.getAccounts();
    console.log(accounts);


    let res = null;
    let events = null;
    let cur = null;

    // ==== 设定ia ====

    let len = await boa.qtyOfDocs();
    len = len.toNumber();

    let list = await boa.docsList();

    let ia = await IA.at(list[len - 1]);
    console.log("ia :", ia.address);

    // ==== voteCounting ====

    let motionId = await web3.utils.hexToNumberString(ia.address);
    console.log("motionId: ", motionId);

    await gk.voteCounting(motionId, {
        from: accounts[2]
    });
    events = await bom.getPastEvents("VoteCounting");
    console.log("Event 'VoteCounting': ", events[0].returnValues);

    let flag = await bom.isPassed(motionId);

    console.log("motion is passed? ", flag);

    // ==== pushToCoffer ====
    res = await ia.getDeal(1);
    cur = await web3.eth.getBlock("latest");

    let closingDate = cur.timestamp + 46400;

    await gk.pushToCoffer(ia.address, res.sn, "0xc2a7aeb6280ec562632de766df6868cb896b986219cbb7239d9b2f9b506f4461", closingDate, {
        from: accounts[2]
    });

    events = await ia.getPastEvents("ClearDealCP");
    console.log("Event 'ClearDealCP': ", events[0].returnValues);

    // ==== closeDeal ====

    // await gk.closeDeal(ia.address, res.sn, "Paul's private key.", {
    //     from: accounts[5]
    // });

    // events = await ia.getPastEvents("CloseDeal");
    // console.log("Event 'CloseDeal': ", events[0].returnValues);

    callback();
}