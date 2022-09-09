const RC = artifacts.require('RegCenter');
const GK = artifacts.require("GeneralKeeper");
const BOH = artifacts.require("BookOfSHA");
const BOHKeeper = artifacts.require("BOHKeeper");
const SHA = artifacts.require("ShareholdersAgreement");

const FR = artifacts.require("FirstRefusal");
const GU = artifacts.require("GroupsUpdate");

module.exports = async function (callback) {

    // ==== 账户准备 ====

    const rc = await RC.deployed();

    const accounts = await web3.eth.getAccounts();
    console.log(accounts);

    const acct2 = await rc.userNo(accounts[2]);
    const acct3 = await rc.userNo(accounts[3]);
    const acct4 = await rc.userNo(accounts[4]);
    const acct5 = await rc.userNo(accounts[5]);

    const gk = await GK.deployed();
    console.log("GeneralKeeper: ", gk.address);

    const bohKeeper = await BOHKeeper.deployed();
    console.log("BOKKeeper: ", bohKeeper.address)

    const boh = await BOH.deployed();
    console.log("BookOfSHA: ", boh.address)

    // ==== 创建SHA ====

    let ret = await gk.createSHA(0, {
        from: accounts[2]
    });

    let events = await boh.getPastEvents("UpdateStateOfDoc");
    console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);

    let addr = ret.logs[0].address;
    console.log("addr of SHA: ", addr);

    const sha = await SHA.at(addr);
    console.log("get SHA: ", sha.address);

    events = await sha.getPastEvents("Init");
    console.log("Event 'Init': ", events[0].returnValues);

    events = await sha.getPastEvents("SetBOC");
    console.log("Event 'SetBOC': ", events[0].returnValues);

    events = await sha.getPastEvents("SetBOS");
    console.log("Event 'SetBOS': ", events[0].returnValues);

    events = await sha.getPastEvents("SetBOSCal");
    console.log("Event 'SetBOSCal': ", events[0].returnValues);

    events = await sha.getPastEvents("SetBOM");
    console.log("Event 'SetBOM': ", events[0].returnValues);

    // ==== 设定 GeneralCounsel ====
    await sha.setManager(2, accounts[2], accounts[7], {
        from: accounts[2]
    });

    events = await rc.getPastEvents("SetManager");
    console.log("Event 'SetManager':", events[0].returnValues);

    const gc = await sha.getManager(2);
    console.log("GC of SHA: ", gc.toNumber());

    // ==== 增加当事方 ====

    await sha.addParty(acct2.toNumber(), {
        from: accounts[7]
    });

    events = await sha.getPastEvents("AddBlank");
    console.log("Event 'AddBlank' : ", events[0].returnValues);

    await sha.addParty(acct3.toNumber(), {
        from: accounts[7]
    });
    events = await sha.getPastEvents("AddBlank");
    console.log("Event 'AddBlank' : ", events[0].returnValues);

    await sha.addParty(acct4.toNumber(), {
        from: accounts[7]
    });

    events = await sha.getPastEvents("AddBlank");
    console.log("Event AddBlank", events[0].returnValues);

    await sha.addParty(acct5.toNumber(), {
        from: accounts[7]
    });

    events = await sha.getPastEvents("AddBlank");
    console.log("Event 'AddBlank' : ", events[0].returnValues);

    await sha.removeBlank(acct5.toNumber(), 0, {
        from: accounts[7]
    });

    events = await sha.getPastEvents("RemoveBlank");
    console.log("Event 'RemoveBlank': ", events[0].returnValues);

    // ==== VotingRules ====
    await sha.setVotingBaseOnPar(1, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetVotingBaseOnPar");
    console.log("Event 'SetVotingBaseOnPar': ", events[0].returnValues);

    await sha.setProposalThreshold(1000, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetProposalThreshold");
    console.log("Event 'SetProposalThreshold': ", events[0].returnValues);

    await sha.setMaxNumOfDirectors(3, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetMaxNumOfDirectors");
    console.log("Event 'SetMaxNumOfDirectors': ", events[0].returnValues);

    await sha.setTenureOfBoard(3, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetTenureOfBoard");
    console.log("Event 'SetTenureOfBoard': ", events[0].returnValues);

    await sha.setAppointerOfChairman(acct2.toNumber(), {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetAppointerOfChairman");
    console.log("Event 'SetAppointerOfChairman': ", events[0].returnValues);

    await sha.setAppointerOfViceChairman(acct3.toNumber(), {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetAppointerOfViceChairman");
    console.log("Event 'SetAppointerOfViceChairman': ", events[0].returnValues);

    // ==== CI ====
    await sha.setRule(1, 0, 0, 6666, 0, 0, 1, 0, 1, 1, 0, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetRule");
    console.log("Event 'SetRule' for CI: ", events[0].returnValues);

    // ==== ST_Ext ====
    await sha.setRule(2, 0, 0, 5000, 1, 1, 1, 1, 1, 1, 0, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetRule");
    console.log("Event 'SetRule' for ST_Ext: ", events[0].returnValues);

    // ==== CI & ST_Ext ====
    await sha.setRule(7, 0, 0, 6666, 0, 0, 1, 0, 1, 1, 0, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetRule");
    console.log("Event 'SetRule' for CI & TS_Ext: ", events[0].returnValues);

    // ==== CI & ST_Int ====
    await sha.setRule(4, 0, 0, 6666, 0, 0, 1, 0, 1, 1, 0, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetRule");
    console.log("Event 'SetRule' for CI & TS_Int: ", events[0].returnValues);

    // ==== ST_Ext & ST_Int ====
    await sha.setRule(5, 0, 0, 5000, 1, 1, 1, 1, 1, 1, 0, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetRule");
    console.log("Event 'SetRule' for ST_Ext & ST_Int: ", events[0].returnValues);

    // ==== CI & ST_Ext & ST_Int ====
    await sha.setRule(6, 0, 0, 6666, 0, 0, 1, 0, 1, 1, 0, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetRule");
    console.log("Event 'SetRule' for CI & ST_Ext & ST_Int: ", events[0].returnValues);

    // ==== FR ====
    ret = await sha.createTerm(3, {
        from: accounts[7]
    });

    addr = ret.logs[0].address;

    let fr = await FR.at(addr);
    console.log("get FR: ", fr.address);

    events = await fr.getPastEvents("Init");
    console.log("Event 'Init': ", events[0].returnValues);

    events = await rc.getPastEvents("SetManager");
    console.log("Event 'SetManager': ", events[0].returnValues);

    events = await fr.getPastEvents("SetBOS");
    console.log("Event 'SetBOS': ", events[0].returnValues);

    events = await fr.getPastEvents("SetBOM");
    console.log("Event 'SetBOM': ", events[0].returnValues);

    events = await sha.getPastEvents("CreateTerm");
    console.log("Event 'CreateTerm': ", events[0].returnValues);

    // ==== remove FR ====
    await sha.removeTerm(3, {
        from: accounts[7]
    });

    events = await sha.getPastEvents("RemoveTerm");
    console.log("Event 'RemoveTerm': ", events[0].returnValues);

    // ==== FR ====
    ret = await sha.createTerm(3, {
        from: accounts[7]
    });

    addr = ret.logs[0].address;

    fr = await FR.at(addr);
    console.log("get FR: ", fr.address);

    events = await fr.getPastEvents("Init");
    console.log("Event 'Init': ", events[0].returnValues);

    events = await rc.getPastEvents("SetManager");
    console.log("Event 'SetManager': ", events[0].returnValues);

    events = await fr.getPastEvents("SetBOS");
    console.log("Event 'SetBOS': ", events[0].returnValues);

    events = await fr.getPastEvents("SetBOM");
    console.log("Event 'SetBOM': ", events[0].returnValues);

    events = await sha.getPastEvents("CreateTerm");
    console.log("Event 'CreateTerm': ", events[0].returnValues);

    // ==== Set FR as per company law of China ====

    await fr.setFirstRefusal(2, 1, 1, 0, {
        from: accounts[7]
    });

    events = await fr.getPastEvents("SetFirstRefusal");
    console.log("Event 'SetFirstRefusal' for ST_Ext: ", events[0].returnValues);

    await fr.delFirstRefusal(2, {
        from: accounts[7]
    });

    events = await fr.getPastEvents("DelFirstRefusal");
    console.log("Event 'DelFirstRefusal' for ST_Ext: ", events[0].returnValues);

    await fr.setFirstRefusal(2, 1, 1, 0, {
        from: accounts[7]
    });

    events = await fr.getPastEvents("SetFirstRefusal");
    console.log("Event 'SetFirstRefusal' for ST_Ext: ", events[0].returnValues);

    await fr.setFirstRefusal(1, 1, 1, 0, {
        from: accounts[7]
    });

    events = await fr.getPastEvents("SetFirstRefusal");
    console.log("Event 'SetFirstRefusal' for CI: ", events[0].returnValues);


    rule = await fr.ruleOfFR(1)
    console.log("FR for CI: ", rule);

    await fr.lockContents({
        from: accounts[7]
    });

    events = await rc.getPastEvents("AbandonRole");
    console.log("Event 'AbandonRole': ", events[0].returnValues);

    events = await rc.getPastEvents("SetManager");
    console.log("Event 'SetManager': ", events[0].returnValues);

    events = await fr.getPastEvents("LockContents");
    console.log("Event 'LockContents': ", events[0].returnValues);



    // ==== 设定签署和生效截止期 =====
    let cur = null;

    cur = Date.parse(new Date()) / 1000;

    await sha.setSigDeadline(cur + 86400, {
        from: accounts[7]
    });

    events = await sha.getPastEvents("SetSigDeadline");
    console.log("Event 'SetSigDeadline': ", events[0].returnValues);

    await sha.setClosingDeadline(cur + 86400, {
        from: accounts[7]
    });

    events = await sha.getPastEvents("SetClosingDeadline");
    console.log("Event 'SetClosingDeadline': ", events[0].returnValues);

    let closingDeadline = await sha.closingDeadline({
        from: accounts[7]
    });
    console.log("closingDeadline of SHA: ", closingDeadline);

    let sigDeadline = await sha.sigDeadline({
        from: accounts[7]
    });
    console.log("sigDeadline :", sigDeadline);

    // ==== SHA finalizeDoc ====

    await sha.finalizeDoc({
        from: accounts[7]
    });

    events = await rc.getPastEvents("AbandonRole");
    console.log("Event 'AbandonRole': ", events[0].returnValues);

    events = await rc.getPastEvents("SetManager");
    console.log("Event 'SetManager': ", events[0].returnValues);

    events = await sha.getPastEvents("LockContents");
    console.log("Event 'LockContents': ", events[0].returnValues);

    events = await sha.getPastEvents("DocFinalized");
    console.log("Event 'DocFinalized': ", events[0].returnValues);

    // ==== CirculateSHA ====

    await gk.circulateSHA(sha.address, {
        from: accounts[2]
    });

    events = await rc.getPastEvents("SetManager");
    console.log("Event 'SetManager': ", events[0].returnValues);

    events = await boh.getPastEvents("UpdateStateOfDoc");
    console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);



    // ==== Signe SHA ====

    await gk.signSHA(sha.address, "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85", {
        from: accounts[2]
    });

    events = await sha.getPastEvents("SignDeal");
    console.log("Event 'SignDeal': ", events[0].returnValues);

    // events = await sha.getPastEvents("DocEstablished");
    // console.log("Event 'DocEstablished': ", events[0].returnValues);

    await gk.signSHA(sha.address, "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85", {
        from: accounts[3]
    });

    events = await sha.getPastEvents("SignDeal");
    console.log("Event 'SignDeal': ", events[0].returnValues);

    await gk.signSHA(sha.address, "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85", {
        from: accounts[4]
    });

    events = await sha.getPastEvents("SignDeal");
    console.log("Event 'SignDeal': ", events[0].returnValues);

    events = await sha.getPastEvents("DocEstablished");
    console.log("Event 'DocEstablished': ", events[0].returnValues);


    await gk.effectiveSHA(sha.address, {
        from: accounts[2]
    });

    events = await boh.getPastEvents("UpdateStateOfDoc");
    console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);

    events = await boh.getPastEvents("ChangePointer");
    console.log("Event 'ChangePointer': ", events[0].returnValues);

    console.log("SHA effectivated.");

    // ==== Query ====

    let res = null;

    res = await sha.tempOfTitle(3);
    console.log("FirstRefusal Template: ", res);

    res = await sha.hasTitle(3);
    console.log("Has FR term? ", res);

    res = await sha.isTitle(4);
    console.log("isTitle: ", res);

    res = await sha.isBody(fr.address);
    console.log("isBody: ", res);

    res = await sha.titles();
    console.log("titles: ", res.map(v => v.toNumber()));

    res = await sha.bodies();
    console.log("bodies: ", res);

    res = await sha.getTerm(3);
    console.log("getTerm FR: ", res);

    res = await sha.votingRules(2);
    console.log("votingRules: ", res);

    res = await sha.basedOnPar();
    console.log("basedOnPar: ", res);

    res = await sha.proposalThreshold();
    console.log("proposalThreshold: ", res.toNumber());

    res = await sha.maxNumOfDirectors();
    console.log("maxNumOfDirectors: ", res.toNumber());

    res = await sha.tenureOfBoard();
    console.log("tenureOfBoard: ", res.toNumber());


    callback();
}