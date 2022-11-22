const BOS = artifacts.require("BookOfShares");
const ROM = artifacts.require("RegisterOfMembers");
const GK = artifacts.require("GeneralKeeper");
const BOSKeeper = artifacts.require("BOSKeeper");
const ROMKeeper = artifacts.require("ROMKeeper");
const RC = artifacts.require("RegCenter");

module.exports = async function (callback) {

    // ==== RegCenter Books and Keepers ====

    const rc = await RC.deployed();
    console.log("rc: ", rc.address);

    const bos = await BOS.deployed();
    console.log("bos: ", bos.address);

    const rom = await ROM.deployed();
    console.log("rom: ", rom.address);

    const gk = await GK.deployed();
    console.log("gk: ", gk.address);

    let res = null;
    let cur = null;
    let events = null;

    // ==== accts register ====

    const accounts = await web3.eth.getAccounts();
    console.log("accts: ", accounts);

    let acct2 = await rc.userNo.call(accounts[2], {
        from: accounts[2]
    });
    acct2 = acct2.toNumber();
    let acct3 = await rc.userNo.call(accounts[3], {
        from: accounts[3]
    });
    acct3 = acct3.toNumber();
    let acct4 = await rc.userNo.call(accounts[4], {
        from: accounts[4]
    });
    acct4 = acct4.toNumber();

    console.log("acct2: ", acct2);

    // ==== config setting ====

    await rom.setMaxQtyOfMembers(50);
    events = await rom.getPastEvents("SetMaxQtyOfMembers");
    console.log("Event 'SetMaxQtyOfMembers': ", events[0].returnValues);

    // ==== IssueShare ====

    cur = Date.parse(new Date()) / 1000;

    let classOfShare = '0000';
    let ssn = '00000001';
    let issueDate = '00000000';
    let shareholder = web3.utils.numberToHex(acct2);

    shareholder = web3.utils.padLeft(shareholder.slice(2, ), 10);
    console.log("shareholder: ", shareholder);

    let shareNumber = '0x' + classOfShare + ssn + issueDate + shareholder;
    shareNumber = web3.utils.padRight(shareNumber, 64);
    console.log("shareNumber: ", shareNumber);

    await bos.issueShare(shareNumber, 500000000, 500000000, cur + 86400);

    events = await rom.getPastEvents("AddMember");
    console.log("Event 'AddMember': ", events[0].returnValues);

    events = await bos.getPastEvents("IssueShare");
    console.log("Event 'IssueShare': ", events[0].returnValues);

    events = await rom.getPastEvents("AddShareToMember");
    console.log("Event 'AddShareToMember': ", events[0].returnValues);

    events = await rom.getPastEvents("CapIncrease");
    console.log("Event 'CapIncrease': ", events[0].returnValues);

    // -- --IssueShare No .2-- --

    cur = Date.parse(new Date()) / 1000;

    classOfShare = '0000';
    ssn = '00000002';
    issueDate = '00000000';

    shareholder = web3.utils.numberToHex(acct3);
    shareholder = web3.utils.padLeft(shareholder.slice(2, ), 10);
    console.log("shareholder: ", shareholder);

    shareNumber = '0x' + classOfShare + ssn + issueDate + shareholder;
    shareNumber = web3.utils.padRight(shareNumber, 64);
    console.log("shareNumber: ", shareNumber);

    await bos.issueShare(shareNumber, 300000000, 300000000, cur + 86400);

    events = await rom.getPastEvents("AddMember");
    console.log("Event 'AddMember': ", events[0].returnValues);

    events = await bos.getPastEvents("IssueShare");
    console.log("Event 'IssueShare': ", events[0].returnValues);

    events = await rom.getPastEvents("AddShareToMember");
    console.log("Event 'AddShareToMember': ", events[0].returnValues);

    events = await rom.getPastEvents("CapIncrease");
    console.log("Event 'CapIncrease': ", events[0].returnValues);

    // ---- IssueShare No.3 ----

    cur = Date.parse(new Date()) / 1000;

    classOfShare = '0000';
    ssn = '00000003';
    issueDate = '00000000';

    shareholder = web3.utils.numberToHex(acct4);
    shareholder = web3.utils.padLeft(shareholder.slice(2, ), 10);
    console.log("shareholder: ", shareholder);

    shareNumber = '0x' + classOfShare + ssn + issueDate + shareholder;
    shareNumber = web3.utils.padRight(shareNumber, 64);
    console.log("shareNumber: ", shareNumber);

    await bos.issueShare(shareNumber, 100000000, 200000000, cur + 86400);

    events = await rom.getPastEvents("AddMember");
    console.log("Event 'AddMember': ", events[0].returnValues);

    events = await bos.getPastEvents("IssueShare");
    console.log("Event 'IssueShare': ", events[0].returnValues);

    events = await rom.getPastEvents("AddShareToMember");
    console.log("Event 'AddShareToMember': ", events[0].returnValues);

    events = await rom.getPastEvents("CapIncrease");
    console.log("Event 'CapIncrease': ", events[0].returnValues);

    // ==== PayInCapital ====

    await bos.setPayInAmount(3, 100000000, "0x6fab4ee53719b2a733996d8b9ce1b89a04d2b877e7f006f90bb73a454e2fdaee");

    events = await bos.getPastEvents("SetPayInAmount");
    console.log("Event 'SetPayInAmount': ", events[0].returnValues);

    await bos.requestPaidInCapital(3, "Paul is an attorney.");

    events = await bos.getPastEvents("PayInCapital");
    console.log("Event 'PayInCapital': ", events[0].returnValues);

    events = await rom.getPastEvents("ChangeAmtOfMember");
    console.log("Event 'ChangeAmtOfMember': ", events[0].returnValues);

    events = await rom.getPastEvents("CapIncrease");
    console.log("Event 'CapIncrease': ", events[0].returnValues);

    // ==== decreaseCapital ====

    await bos.decreaseCapital(1, 100000000, 100000000);

    events = await bos.getPastEvents("SubAmountFromShare");
    console.log("Event 'SubAmountFromShare': ", events[0].returnValues);

    events = await rom.getPastEvents("CapDecrease");
    console.log("Event 'CapDecrease': ", events[0].returnValues);

    // ==== UpdateShareState ====

    await bos.updateStateOfShare(1, 4);

    events = await bos.getPastEvents("UpdateStateOfShare");
    console.log("Event 'UpdateStateOfShare': ", events[0].returnValues);

    res = await bos.getShare(1);
    console.log("state of share_1: ", res.state.toNumber());

    await bos.updateStateOfShare(1, 0);

    events = await bos.getPastEvents("UpdateStateOfShare");
    console.log("Event 'UpdateStateOfShare': ", events[0].returnValues);

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

    let bn = await web3.eth.getBlockNumber();

    res = await bos.isShare(55);
    console.log("isShare: ", res);

    res = await bos.isShare(2);
    console.log("isShare: ", res);

    res = await bos.cleanPar(1);
    console.log("cleanPar of share_1: ", res.toNumber());

    res = await bos.getShare(3);
    console.log("details of share_3: ShareNumber: ", res.shareNumber, "Par: ", res.par.toNumber(), "Paid: ", res.paid.toNumber(), "PaidInDeadline: ", res.paidInDeadline.toNumber(), "State: ", res.state.toNumber());

    // ==== ROM ====

    res = await rom.maxQtyOfMembers();
    console.log("maxQtyOfMembers: ", res.toNumber());

    res = await rom.parCap();
    console.log("parCap: ", res.toNumber());

    res = await rom.paidCap();
    console.log("paidCap: ", res.toNumber());

    res = await rom.capAtBlock(bn);
    console.log("capAtBlock: parValue: ", res.par.toNumber(), "paidPar: ", res.paid.toNumber());

    res = await rom.totalVotes();
    console.log("totalVotes: ", res.toNumber());

    res = await rom.sharesList();
    console.log("sharesList: ", res);

    res = await rom.sharenumberExist("0x000000000001636cf10a00000000140000000000000000000000000000000000");
    console.log("sharenumberExist: ", res);

    let acct5 = await rc.userNo.call(accounts[5], {
        from: accounts[5]
    });

    res = await rom.isMember(acct5.toNumber());
    console.log("isMember: ", res);

    res = await rom.isMember(acct3);
    console.log("isMember: ", res);

    res = await rom.paidOfMember(acct2);
    console.log("paidOfMember of acct2: ", res.toNumber());

    res = await rom.parOfMember(acct2);
    console.log("parOfMember of acct2: ", res.toNumber());

    res = await rom.votesInHand(acct2);
    console.log("votesInHand of acct2: ", res.toNumber());

    res = await rom.votesAtBlock(acct2, bn);
    console.log("votesAtBlock of acct2: ", res);

    res = await rom.sharesInHand(acct2);
    console.log("sharesInHand of acct2: ", res);

    res = await rom.groupNo(acct2);
    console.log("groupNo of acct2: ", res.toNumber());

    res = await rom.qtyOfMembers();
    console.log("qtyOfMembers: ", res.toNumber());

    res = await rom.membersList();
    console.log("membersList: ", res.map(v => v.toNumber()));

    // ==== HandOver keeper rights ====

    const bosKeeper = await BOSKeeper.deployed();
    await bos.setBookeeper(bosKeeper.address);

    const romKeeper = await ROMKeeper.deployed();
    await rom.setBookeeper(romKeeper.address);

    callback();
}