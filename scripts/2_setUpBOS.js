const BOS = artifacts.require("BookOfShares");
const GK = artifacts.require("GeneralKeeper");
const BOSKeeper = artifacts.require("BOSKeeper");
const RC = artifacts.require("RegCenter");

module.exports = async function (callback) {

    // ==== RegCenter Books and Keepers ====

    const rc = await RC.deployed();
    console.log("rc: ", rc.address);

    const bos = await BOS.deployed();
    console.log("bos: ", bos.address);

    const gk = await GK.deployed();
    console.log("gk: ", gk.address);

    let res = null;
    let cur = null;
    let events = null;

    // ==== accts register ====

    const accounts = await web3.eth.getAccounts();
    console.log("accts: ", accounts);

    const acct2 = await rc.userNo(accounts[2]);
    const acct3 = await rc.userNo(accounts[3]);
    const acct4 = await rc.userNo(accounts[4]);

    // ==== IssueShare ====

    cur = Date.parse(new Date()) / 1000;

    await bos.issueShare(acct2.toNumber(), 0, 500000000, 500000000, cur + 86400, cur, 1);

    events = await bos.getPastEvents("AddMember");
    console.log("Event 'AddMember': ", events[0].returnValues);

    events = await bos.getPastEvents("IssueShare");
    console.log("Event 'IssueShare': ", events[0].returnValues);

    events = await bos.getPastEvents("IncreaseAmountToMember");
    console.log("Event 'IncreaseAmountToMember': ", events[0].returnValues);

    events = await bos.getPastEvents("AddShareToMember");
    console.log("Event 'AddShareToMember': ", events[0].returnValues);

    events = await bos.getPastEvents("CapIncrease");
    console.log("Event 'CapIncrease': ", events[0].returnValues);

    // ---- IssueShare No.2 ----

    cur = Date.parse(new Date()) / 1000;

    await bos.issueShare(acct3.toNumber(), 0, 300000000, 300000000, cur + 86400, cur, 1);

    events = await bos.getPastEvents("AddMember");
    console.log("Event 'AddMember': ", events[0].returnValues);

    events = await bos.getPastEvents("IssueShare");
    console.log("Event 'IssueShare': ", events[0].returnValues);

    events = await bos.getPastEvents("IncreaseAmountToMember");
    console.log("Event 'IncreaseAmountToMember': ", events[0].returnValues);

    events = await bos.getPastEvents("AddShareToMember");
    console.log("Event 'AddShareToMember': ", events[0].returnValues);

    events = await bos.getPastEvents("CapIncrease");
    console.log("Event 'CapIncrease': ", events[0].returnValues);

    // ---- IssueShare No.3 ----

    cur = Date.parse(new Date()) / 1000;

    await bos.issueShare(acct4.toNumber(), 0, 200000000, 100000000, cur + 86400, cur, 1);

    events = await bos.getPastEvents("AddMember");
    console.log("Event 'AddMember': ", events[0].returnValues);

    events = await bos.getPastEvents("IssueShare");
    console.log("Event 'IssueShare': ", events[0].returnValues);

    events = await bos.getPastEvents("IncreaseAmountToMember");
    console.log("Event 'IncreaseAmountToMember': ", events[0].returnValues);

    events = await bos.getPastEvents("AddShareToMember");
    console.log("Event 'AddShareToMember': ", events[0].returnValues);

    events = await bos.getPastEvents("CapIncrease");
    console.log("Event 'CapIncrease': ", events[0].returnValues);

    // ==== decreaseCapital ====

    await bos.decreaseCapital(1, 100000000, 100000000);

    events = await bos.getPastEvents("SubAmountFromShare");
    console.log("Event 'SubAmountFromShare': ", events[0].returnValues);

    events = await bos.getPastEvents("DecreaseAmountFromMember");
    console.log("Event 'DecreaseAmountFromMember': ", events[0].returnValues);

    events = await bos.getPastEvents("CapDecrease");
    console.log("Event 'CapDecrease': ", events[0].returnValues);

    // ==== CleanPar ====

    await bos.decreaseCleanPar(1, 100000000);

    events = await bos.getPastEvents("DecreaseCleanPar");
    console.log("Event 'DecreaseCleanPar': ", events[0].returnValues);

    res = await bos.cleanPar(1);
    console.log("cleanPar of share_1: ", res.toNumber());

    await bos.increaseCleanPar(1, 100000000);

    events = await bos.getPastEvents("IncreaseCleanPar");
    console.log("Event 'IncreaseCleanPar': ", events[0].returnValues);

    res = await bos.cleanPar(1);
    console.log("cleanPar of share_1: ", res.toNumber());

    // ==== UpdateShareState ====

    await bos.updateShareState(1, 4);

    events = await bos.getPastEvents("UpdateShareState");
    console.log("Event 'UpdateShareState': ", events[0].returnValues);

    res = await bos.getShare(1);
    console.log("state of share_1: ", res.state.toNumber());

    await bos.updateShareState(1, 0);

    events = await bos.getPastEvents("UpdateShareState");
    console.log("Event 'UpdateShareState': ", events[0].returnValues);

    res = await bos.getShare(1);
    console.log("state of share_1: ", res.state.toNumber());

    // ==== UpdatePaidInDeadline ====

    cur = Date.parse(new Date()) / 1000;

    await bos.updatePaidInDeadline(1, cur + 172800);

    events = await bos.getPastEvents("UpdatePaidInDeadline");
    console.log("Event 'UpdatePaidInDeadline': ", events[0].returnValues);

    await bos.updatePaidInDeadline(1, cur + 86400);

    events = await bos.getPastEvents("UpdatePaidInDeadline");
    console.log("Event 'UpdatePaidInDeadline': ", events[0].returnValues);

    // ==== Query ====

    res = await bos.counterOfShares();
    console.log("counterOfShares: ", res.toNumber());

    res = await bos.counterOfClasses();
    console.log("counterOfClasses: ", res.toNumber());

    res = await bos.regCap();
    console.log("regCap: ", res.toNumber());

    res = await bos.paidCap();
    console.log("paidCap: ", res.toNumber());

    let bn = await web3.eth.getBlockNumber();

    res = await bos.capAtBlock(bn);
    console.log("capAtBlock: parValue: ", res.par.toNumber(), "paidPar: ", res.paid.toNumber());

    res = await bos.isShare(55);
    console.log("isShare: ", res);

    res = await bos.isShare(2);
    console.log("isShare: ", res);

    res = await bos.snList();
    console.log("snList: ", res);

    res = await bos.cleanPar(1);
    console.log("cleanPar of share_1: ", res.toNumber());

    res = await bos.getShare(3);
    console.log("details of share_3: ShareNumber: ", res.shareNumber, "ParValue: ", res.parValue.toNumber(), "PaidPar: ", res.paidPar.toNumber(), "PaidInDeadline: ", res.paidInDeadline.toNumber(), "UnitPrice: ", res.unitPrice.toNumber(), "State: ", res.state.toNumber());

    res = await bos.maxQtyOfMembers();
    console.log("maxQtyOfMembers: ", res.toNumber());

    let acct5 = await rc.userNo(accounts[5]);

    res = await bos.isMember(acct5.toNumber());
    console.log("isMember: ", res);

    res = await bos.isMember(acct3.toNumber());
    console.log("isMember: ", res);

    res = await bos.members();
    console.log("members: ", res.map(m => m.toNumber()));

    res = await bos.qtyOfMembersAtBlock(bn);
    console.log("qtyOfMembersAtBlock: ", res.toNumber());

    res = await bos.parInHand(acct2.toNumber());
    console.log("parInHand of acct2: ", res.toNumber());

    res = await bos.paidInHand(acct2.toNumber());
    console.log("paidInHand of acct2: ", res.toNumber());

    res = await bos.sharesInHand(acct2.toNumber());
    console.log("sharesInHand of acct2: ", res);

    // ==== HandOver keeper rights ====

    const bosKeeper = await BOSKeeper.deployed();
    await bos.setManager(1, accounts[0], bosKeeper.address);

    events = await rc.getPastEvents("SetManager");

    console.log("Event 'SetManager': ", events[0].returnValues);

    callback();
}