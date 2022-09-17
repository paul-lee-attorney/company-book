const BOS = artifacts.require("BookOfShares");
const BOM = artifacts.require("BookOfMotions");
const BOA = artifacts.require("BookOfIA");

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

    const boaKeeper = await BOAKeeper.deployed();
    console.log("BOAKeeper address: ", boaKeeper.address);

    const accounts = await web3.eth.getAccounts();
    console.log(accounts);

    const rc = await RC.deployed();
    console.log("RegCenter: ", rc.address);

    const bos = await BOS.deployed();
    console.log("BookOfShares: ", bos.address);

    let addr = null;
    let events = null;
    let cur = null;
    let receipt = null;

    // ==== 创建IA ====
    receipt = await gk.createIA("0", {
        from: accounts[2]
    });

    addr = receipt.logs[0].address;
    console.log("IA address: ", addr);

    const ia = await IA.at(addr);
    console.log("get ia: ", ia.address);

    // ==== 设定 GeneralCounsel ====
    await ia.setManager(2, accounts[2], accounts[7], {
        from: accounts[2]
    });

    events = await rc.getPastEvents("SetManager");
    console.log("Event 'SetManager': ", events[0].returnValues);

    let attorney = await ia.getManager("2");
    console.log("GC to IA is: ", attorney.toNumber());

    // ==== 设定签署和生效截止期 ====
    // cur = Date.parse(new Date()) / 1000;
    cur = await web3.eth.getBlock("latest");
    let timestamp = cur.timestamp;

    await ia.setSigDeadline(timestamp + 86400, {
        from: accounts[7]
    });

    events = await ia.getPastEvents("SetSigDeadline");
    console.log("Event 'SetSigDeadline': ", events[0].returnValues);

    await ia.setClosingDeadline(timestamp + 86400 * 3, {
        from: accounts[7]
    });

    events = await ia.getPastEvents("SetClosingDeadline");
    console.log("Event 'SetClosingDeadline': ", events[0].returnValues);

    // ==== Draft IA ====

    let acct5 = await rc.userNo(accounts[5]);

    // ==== 股转交易 ====

    let share1 = await bos.getShare(1);

    await ia.createDeal(2, share1.shareNumber, 0, acct5.toNumber(), 0, {
        from: accounts[7]
    });

    events = await ia.getPastEvents("CreateDeal");
    console.log("Event 'CreateDeal': ", events[0].returnValues);

    let sn = null;
    sn = events[0].returnValues.sn;

    await ia.updateDeal(1, 150, 100000000, 100000000, timestamp + 86400 * 2, {
        from: accounts[7]
    });

    events = await ia.getPastEvents("UpdateDeal");
    console.log("Event 'UpdateDeal': ", events[0].returnValues);

    let parties = await ia.parties();
    console.log("parties: ", parties.map(v => v.toNumber()));


    // ==== 确定IA签署方 ====
    let acct2 = await rc.userNo(accounts[2]);

    await ia.addParty(acct2.toNumber(), {
        from: accounts[7]
    });

    await ia.addParty(acct5.toNumber(), {
        from: accounts[7]
    });

    // 验证IA当事方
    let qtyOfParties = await ia.qtyOfParties({
        from: accounts[7]
    });
    console.log("Qty of parties of IA: ", qtyOfParties.toNumber());

    parties = await ia.parties();
    console.log("parties: ", parties.map(v => v.toNumber()));

    // 定稿IA
    await ia.finalizeDoc({
        from: accounts[7]
    });

    events = await ia.getPastEvents("DocFinalized");
    console.log("Event 'DocFinalized': ", events[0].returnValues);

    // 分发IA（ 创建股东）
    await gk.circulateIA(ia.address, {
        from: accounts[2]
    });

    events = await rc.getPastEvents("SetManager");
    console.log("Event 'SetManager': ", events[0].returnValues);

    events = await boa.getPastEvents("UpdateStateOfDoc");
    console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);

    // ==== 签署IA ====
    await gk.signIA(ia.address, "0xd3cbe222ebe6a7fa1dc87ecc76555c40943e8ec1f6a91c5cf479509accb1ef5a", {
        from: accounts[2]
    });
    events = await ia.getPastEvents("SignDeal");
    console.log("Event 'SignDeal': ", events[0].returnValues);

    await gk.signIA(ia.address, "0xe5b0e7ffcb90dc5ee09f49282b47da64e12e0b36c689866cb8363f0be8027ffb", {
        from: accounts[5]
    });
    events = await ia.getPastEvents("SignDeal");
    console.log("Event 'SignDeal': ", events[0].returnValues);

    events = await ia.getPastEvents("DocEstablished");
    console.log("Event 'DocEstablished': ", events[0].returnValues);

    // ==== 快速累加 BlockNumber 和 timestamp ====

    let bn = await web3.eth.getBlockNumber();
    console.log("current BN: ", bn);

    cur = await web3.eth.getBlock("latest");
    console.log("current timestamp: ", cur.timestamp);

    await web3.currentProvider.send({
        method: "evm_increaseTime",
        params: [86400]
    }, () => {});

    let i = null;
    for (i = 0; i < 240; i++) {
        await web3.currentProvider.send({
            method: "evm_mine"
        }, () => {});
    }

    bn = await web3.eth.getBlockNumber();
    console.log("current BN: ", bn);

    cur = await web3.eth.getBlock(bn);
    console.log("current timestamp: ", cur.timestamp);

    // ==== 提交IA ====

    await gk.proposeMotion(ia.address, {
        from: accounts[2]
    });

    events = await bom.getPastEvents("ProposeMotion");
    console.log("Event 'ProposeMotion': ", events[0].returnValues);

    events = await boa.getPastEvents("UpdateStateOfDoc");
    console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);

    // ==== Vote ====

    await gk.castVote(ia.address, 1, "0xe5b0e7ffcb90dc5ee09f49282b47da64e12e0b36c689866cb8363f0be8027ffb", {
        from: accounts[3]
    });
    events = await bom.getPastEvents("CastVote");
    console.log("Event 'CastVote': ", events[0].returnValues);

    await gk.castVote(ia.address, 1, "0xe5b0e7ffcb90dc5ee09f49282b47da64e12e0b36c689866cb8363f0be8027ffb", {
        from: accounts[4]
    });
    events = await bom.getPastEvents("CastVote");
    console.log("Event 'CastVote': ", events[0].returnValues);

    // ==== 快速累加 BlockNumber 和 timestamp ====

    bn = await web3.eth.getBlockNumber();
    console.log("current BN: ", bn);

    cur = await web3.eth.getBlock("latest");
    console.log("current timestamp: ", cur.timestamp);

    await web3.currentProvider.send({
        method: "evm_increaseTime",
        params: [86400]
    }, () => {});

    for (i = 0; i < 240; i++) {
        await web3.currentProvider.send({
            method: "evm_mine"
        }, () => {});
    }

    bn = await web3.eth.getBlockNumber();
    console.log("current BN: ", bn);

    cur = await web3.eth.getBlock(bn);
    console.log("current timestamp: ", cur.timestamp);

    // ==== voteCounting ====

    await gk.voteCounting(ia.address, {
        from: accounts[2]
    });
    events = await bom.getPastEvents("VoteCounting");
    console.log("Event 'VoteCounting': ", events[0].returnValues);

    let flag = await bom.isPassed(ia.address);
    console.log("motion is passed? ", flag.toString());

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

    await gk.closeDeal(ia.address, res.sn, "Paul's private key.", {
        from: accounts[5]
    });

    events = await ia.getPastEvents("CloseDeal");
    console.log("Event 'CloseDeal': ", events[0].returnValues);

    callback();
}