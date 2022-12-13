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

    const gk = await GK.deployed();
    console.log("GeneralKeeper address: ", gk.address);

    const boa = await BOA.deployed();
    console.log("BookOfIA: ", boa.address);

    const bom = await BOM.deployed();
    console.log("BookOfMotion: ", bom.address);

    const boaKeeper = await BOAKeeper.deployed();
    console.log("BOAKeeper address: ", boaKeeper.address);

    const accounts = await web3.eth.getAccounts();
    console.log(accounts);

    const rc = await RC.deployed();
    console.log("RegCenter: ", rc.address);

    const boh = await BOH.deployed();

    const bos = await BOS.deployed();
    console.log("BookOfShares: ", bos.address);


    let acct7 = await rc.userNo.call(accounts[7], {
        from: accounts[7]
    });

    let ret = null;
    let addr = null;
    let events = null;
    let cur = null;


    // ==== 创建IA ====
    await gk.createIA(0, {
        from: accounts[2]
    });

    let list = await boa.docsList();
    let len = await boa.qtyOfDocs();

    addr = list[len - 1];

    let ia = await IA.at(addr);
    console.log("get ia: ", ia.address);

    // ==== 设定 GeneralCounsel ====
    await ia.setManager(1, acct7, {
        from: accounts[2]
    });

    events = await ia.getPastEvents("SetManager");
    console.log("Event 'SetManager': ", events[0].returnValues);

    let gc = await ia.getManager("1");
    gc = gc.toNumber();
    console.log("GC to IA is: ", gc);

    // ==== 设定签署和生效截止期 ====
    // cur = Date.parse(new Date()) / 1000;
    cur = await web3.eth.getBlock("latest");
    let timestamp = cur.timestamp;
    console.log("timestamp: ", timestamp);

    timestamp = timestamp + 86400;

    await ia.setSigDeadline(timestamp, {
        from: accounts[7]
    });
    console.log("sigDeadline: ", timestamp);

    timestamp = timestamp + 86400 * 23;

    await ia.setClosingDeadline(timestamp, {
        from: accounts[7]
    });
    console.log("closingDeadline: ", timestamp);

    // ==== 股转交易 ====

    let classOfShare = '0000';
    let seq = '0001';
    let typeOfDeal = '02';
    let seller = '0000000004';
    let buyer = '0000000007';
    let groupOfBuyer = '0000000007';
    let ssn = '00000001';
    let price = '000000c8';

    sn = '0x' + classOfShare + seq + typeOfDeal + seller + buyer + groupOfBuyer + ssn + price;

    sn = web3.utils.padRight(sn, 64);
    console.log("sn: ", sn);

    await ia.createDeal(sn, 10000, 10000, timestamp, {
        from: accounts[7]
    });

    events = await ia.getPastEvents("CreateDeal");
    console.log("Event 'CreateDeal': ", events[0].returnValues);

    let parties = await ia.partiesOfDoc();
    console.log("parties: ", parties.map(v => v.toNumber()));

    await ia.setTypeOfIA(2, {
        from: accounts[7]
    });

    ret = await ia.typeOfIA();
    console.log("typeOfIA: ", ret.toNumber());

    // ==== circulate IA ====

    let docHash = '0xd3cbe222ebe6a7fa1dc87ecc76555c40943e8ec1f6a91c5cf479509accb1ef5a';

    await gk.circulateIA(ia.address, docHash, {
        from: accounts[2]
    });

    events = await ia.getPastEvents("LockContents");
    console.log("Event 'LockContents': ", events[0].returnValues);

    events = await ia.getPastEvents("SetManager");
    console.log("Event 'SetManager': ", events[0].returnValues);

    events = await boa.getPastEvents("UpdateStateOfDoc");
    console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);

    // ==== 签署IA ====
    await gk.signIA(ia.address, "0xd3cbe222ebe6a7fa1dc87ecc76555c40943e8ec1f6a91c5cf479509accb1ef5a", {
        from: accounts[2]
    });

    await gk.signIA(ia.address, "0xe5b0e7ffcb90dc5ee09f49282b47da64e12e0b36c689866cb8363f0be8027ffb", {
        from: accounts[5]
    });

    ret = await ia.established();
    console.log("ia established: ", ret);

    ret = await boa.currentState(ia.address);
    console.log("docsRepo status: ", ret.toNumber());

    // ==== ProposeIA ====

    await gk.proposeIA(ia.address, {
        from: accounts[2]
    });

    events = await boa.getPastEvents("UpdateStateOfDoc");
    console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);

    // ==== 快进15天（BlockNumber 和 timestamp）====

    console.log("start: ", await getCurrentBN(web3), await getCurrentTime(web3));
    await advanceDays(15, web3);
    console.log("end: ", await getCurrentBN(web3), await getCurrentTime(web3));

    callback();
}