const RC = artifacts.require('RegCenter');
const GK = artifacts.require("GeneralKeeper");
const BOH = artifacts.require("BookOfSHA");
const BOHKeeper = artifacts.require("BOHKeeper");
const SHA = artifacts.require("ShareholdersAgreement");

const FR = artifacts.require("FirstRefusal");
const GU = artifacts.require("GroupsUpdate");

module.exports = async function (callback) {

    // ==== 账户准备 ====

    let rc = await RC.deployed();

    let accounts = await web3.eth.getAccounts();
    console.log(accounts);

    let acct2 = await rc.userNo.call(accounts[2], {
        from: accounts[2]
    });
    let acct3 = await rc.userNo.call(accounts[3], {
        from: accounts[3]
    });
    let acct4 = await rc.userNo.call(accounts[4], {
        from: accounts[4]
    });
    let acct5 = await rc.userNo.call(accounts[5], {
        from: accounts[5]
    });
    let acct7 = await rc.userNo.call(accounts[7], {
        from: accounts[7]
    });

    acct2 = acct2.toNumber();
    acct3 = acct3.toNumber();
    acct4 = acct4.toNumber();
    acct5 = acct5.toNumber();
    acct7 = acct7.toNumber();

    let gk = await GK.deployed();
    console.log("GeneralKeeper: ", gk.address);

    let bohKeeper = await BOHKeeper.deployed();
    console.log("BOKKeeper: ", bohKeeper.address)

    let boh = await BOH.deployed();
    console.log("BookOfSHA: ", boh.address)

    // ==== 创建SHA ====

    let ret = await gk.createSHA(0, {
        from: accounts[2]
    });

    events = await boh.getPastEvents("UpdateStateOfDoc");
    console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);

    let addr = ret.logs[0].address;
    console.log("addr of SHA: ", addr);

    let sha = await SHA.at(addr);
    console.log("get SHA: ", sha.address);

    events = await sha.getPastEvents("SetRegCenter");
    console.log("Event 'SetRegCenter': ", events[0].returnValues);

    events = await sha.getPastEvents("SetGeneralKeeper");
    console.log("Event 'SetGeneralKeeper': ", events[0].returnValues);

    events = await sha.getPastEvents("Init");
    console.log("Event 'Init': ", events[0].returnValues);

    // ==== 设定 GeneralCounsel ====
    await sha.setManager(1, acct7, {
        from: accounts[2]
    });

    events = await sha.getPastEvents("SetManager");
    console.log("Event 'SetManager':", events[0].returnValues);

    let gc = await sha.getManager(1);
    gc = gc.toNumber();
    console.log("GC of SHA: ", gc);

    // ==== 增加当事方 ====

    await sha.addParty(acct2, {
        from: accounts[7]
    });
    console.log("add Acct2 as party.")

    await sha.addParty(acct3, {
        from: accounts[7]
    });
    console.log("add Acct3 as party.")

    await sha.addParty(acct4, {
        from: accounts[7]
    });
    console.log("add Acct4 as party.")

    await sha.addParty(acct5, {
        from: accounts[7]
    });
    console.log("add Acct5 as party.")

    await sha.removeBlank(acct5, 0, {
        from: accounts[7]
    });
    console.log("remove Acct5.")

    ret = await sha.partiesOfDoc();
    console.log("Parties of SHA: ", ret.map(v => v.toNumber()));

    // ==== GoverningRules ====
    let seqOfRule = '0000';
    let basedOnPar = '00';
    let proposalThreshold = '03e8';
    let maxNumOfDirectors = '03';
    let tenureOfBoard = '03';

    let rule = '0x' + seqOfRule + basedOnPar + proposalThreshold + maxNumOfDirectors + tenureOfBoard;

    rule = web3.utils.padRight(rule, 64);
    console.log("GovernanceRule: ", rule);

    await sha.addRule(rule, {
        from: accounts[7]
    });
    console.log("Governing Rule already set.")

    ret = await sha.basedOnPar();
    console.log("Event 'basedOnPar': ", ret);

    ret = await sha.proposalThreshold();
    console.log("Event 'proposalThreshold': ", ret.toNumber());

    ret = await sha.maxNumOfDirectors();
    console.log("Event 'maxNumOfDirectors': ", ret.toNumber());

    ret = await sha.tenureOfBoard();
    console.log("Event 'tenureOfBoard': ", ret.toNumber());

    // ==== CI VotingRule ====

    seqOfRule = '0001';
    let ratioHead = '0000';
    let ratioAmount = '1a0a';
    let onlyAttendance = '00';
    let impliedConsent = '00';
    let partyAsConsent = '01';
    let againstShallBuy = '00';
    let shaExecDays = '00';
    let reviewDays = '0f';
    let votingDays = '07';
    let execDaysForPutOpt = '07';

    rule = '0x' + seqOfRule + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + shaExecDays + reviewDays + votingDays + execDaysForPutOpt;

    rule = web3.utils.padRight(rule, 64);
    console.log("rule: ", rule);

    await sha.addRule(rule, {
        from: accounts[7]
    });

    ret = await sha.votingRules(1);
    console.log("VotingRules for typeOfVote: ", seqOfRule, " rule: ", ret);

    // ==== SText VotingRule ====

    seqOfRule = '0002';
    ratioHead = '0000';
    ratioAmount = '1388';
    onlyAttendance = '00';
    impliedConsent = '01';
    partyAsConsent = '01';
    againstShallBuy = '01';
    shaExecDays = '00';
    reviewDays = '0f';
    votingDays = '07';
    execDaysForPutOpt = '07';

    rule = '0x' + seqOfRule + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + shaExecDays + reviewDays + votingDays + execDaysForPutOpt;

    rule = web3.utils.padRight(rule, 64);
    console.log("rule: ", rule);

    await sha.addRule(rule, {
        from: accounts[7]
    });

    ret = await sha.votingRules(seqOfRule);
    console.log("VotingRules for typeOfVote: ", seqOfRule, " rule: ", ret);

    // ==== STint ====

    seqOfRule = '0003';
    ratioHead = '0000';
    ratioAmount = '0000';
    onlyAttendance = '00';
    impliedConsent = '01';
    partyAsConsent = '01';
    againstShallBuy = '01';
    shaExecDays = '00';
    reviewDays = '00';
    votingDays = '00';
    execDaysForPutOpt = '07';

    rule = '0x' + seqOfRule + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + shaExecDays + reviewDays + votingDays + execDaysForPutOpt;

    rule = web3.utils.padRight(rule, 64);
    console.log("rule: ", rule);

    await sha.addRule(rule, {
        from: accounts[7]
    });

    ret = await sha.votingRules(seqOfRule);
    console.log("VotingRules for typeOfVote: ", seqOfRule, " rule: ", ret);

    // ==== CI & STint ====

    seqOfRule = '0004';
    ratioHead = '0000';
    ratioAmount = '1a0a';
    onlyAttendance = '00';
    impliedConsent = '00';
    partyAsConsent = '01';
    againstShallBuy = '00';
    shaExecDays = '00';
    reviewDays = '0f';
    votingDays = '07';
    execDaysForPutOpt = '07';

    rule = '0x' + seqOfRule + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + shaExecDays + reviewDays + votingDays + execDaysForPutOpt;

    rule = web3.utils.padRight(rule, 64);
    console.log("rule: ", rule);

    await sha.addRule(rule, {
        from: accounts[7]
    });

    ret = await sha.votingRules(seqOfRule);
    console.log("VotingRules for typeOfVote: ", seqOfRule, " rule: ", ret);
    // ==== SText & STint ====

    seqOfRule = '0005';
    ratioHead = '0000';
    ratioAmount = '1388';
    onlyAttendance = '00';
    impliedConsent = '01';
    partyAsConsent = '01';
    againstShallBuy = '01';
    shaExecDays = '00';
    reviewDays = '0f';
    votingDays = '07';
    execDaysForPutOpt = '07';

    rule = '0x' + seqOfRule + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + shaExecDays + reviewDays + votingDays + execDaysForPutOpt;

    rule = web3.utils.padRight(rule, 64);
    console.log("rule: ", rule);

    ret = await sha.addRule(rule, {
        from: accounts[7]
    });

    ret = await sha.votingRules(seqOfRule);
    console.log("VotingRules for typeOfVote: ", seqOfRule, " rule: ", ret);

    // ==== CI & SText & STint ====

    seqOfRule = '0006';
    ratioHead = '0000';
    ratioAmount = '1a0a';
    onlyAttendance = '00';
    impliedConsent = '00';
    partyAsConsent = '01';
    againstShallBuy = '00';
    shaExecDays = '00';
    reviewDays = '0f';
    votingDays = '07';
    execDaysForPutOpt = '07';

    rule = '0x' + seqOfRule + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + shaExecDays + reviewDays + votingDays + execDaysForPutOpt;

    rule = web3.utils.padRight(rule, 64);
    console.log("rule: ", rule);

    await sha.addRule(rule, {
        from: accounts[7]
    });

    ret = await sha.votingRules(seqOfRule);
    console.log("VotingRules for typeOfVote: ", seqOfRule, " rule: ", ret);

    // ==== CI & SText ====

    seqOfRule = '0007';
    ratioHead = '0000';
    ratioAmount = '1a0a';
    onlyAttendance = '00';
    impliedConsent = '00';
    partyAsConsent = '01';
    againstShallBuy = '00';
    shaExecDays = '00';
    reviewDays = '0f';
    votingDays = '07';

    rule = '0x' + seqOfRule + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + shaExecDays + reviewDays + votingDays + execDaysForPutOpt;

    rule = web3.utils.padRight(rule, 64);
    console.log("rule: ", rule);

    await sha.addRule(rule, {
        from: accounts[7]
    });

    ret = await sha.votingRules(seqOfRule);
    console.log("VotingRules for typeOfVote: ", seqOfRule, " rule: ", ret);

    // ==== FR rule for CI ====

    // struct ruleInfo {
    //     uint8 seqOfRule;
    //     uint8 typeOfDeal;
    //     bool membersEqual;
    //     bool proRata;
    //     bool basedOnPar;
    // }
    let typeOfDeal = '01';

    rule = '0x' + '0015' + typeOfDeal + '01' + '01' + '00';
    rule = web3.utils.padRight(rule, 64);
    console.log("FR : ", rule);

    await sha.addRule(rule, {
        from: accounts[7]
    });

    ret = await sha.ruleOfFR(typeOfDeal);
    console.log("return of ruleOfFR: ", ret);

    // ==== FR rule for SText ====

    typeOfDeal = '02';

    rule = '0x' + '0016' + typeOfDeal + '01' + '01' + '00';
    rule = web3.utils.padRight(rule, 64);
    console.log("FR : ", rule);

    await sha.addRule(rule, {
        from: accounts[7]
    });

    ret = await sha.ruleOfFR(typeOfDeal);
    console.log("return of ruleOfFR: ", ret);

    // ==== FR rule for STint ====

    typeOfDeal = '03';

    rule = '0x' + '0017' + typeOfDeal + '01' + '01' + '00';
    rule = web3.utils.padRight(rule, 64);
    console.log("FR : ", rule);

    await sha.addRule(rule, {
        from: accounts[7]
    });

    ret = await sha.ruleOfFR(typeOfDeal);
    console.log("return of ruleOfFR: ", ret);

    // ==== 设定签署和生效截止期 =====
    let cur = null;

    // cur = Date.parse(new Date()) / 1000;
    cur = await web3.eth.getBlock("latest");

    await sha.setSigDeadline(cur.timestamp + 86400, {
        from: accounts[7]
    });

    await sha.setClosingDeadline(cur.timestamp + 86400, {
        from: accounts[7]
    });

    let closingDeadline = await sha.closingDeadline({
        from: accounts[7]
    });
    console.log("closingDeadline of SHA: ", closingDeadline);

    let sigDeadline = await sha.sigDeadline({
        from: accounts[7]
    });
    console.log("sigDeadline :", sigDeadline);

    // ==== circulate SHA ====

    let docHash = "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85";

    await gk.circulateSHA(sha.address, docHash, {
        from: accounts[2]
    });

    events = await sha.getPastEvents("LockContents");
    console.log("Event SHA 'LockContents': ", events[0].returnValues);

    events = await sha.getPastEvents("SetManager");
    console.log("Event SHA 'SetManager': ", events[0].returnValues);

    events = await boh.getPastEvents("UpdateStateOfDoc");
    console.log("Event SHA 'UpdateStateOfDoc': ", events[0].returnValues);

    // ==== Signe SHA ====

    await gk.signSHA(sha.address, "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85", {
        from: accounts[2]
    });

    ret = await sha.sigOfDeal(acct2, 0);
    console.log("sigOfDeal: ", ret);

    await gk.signSHA(sha.address, "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85", {
        from: accounts[3]
    });

    ret = await sha.sigOfDeal(acct3, 0);
    console.log("sigOfDeal: ", ret);

    await gk.signSHA(sha.address, "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85", {
        from: accounts[4]
    });

    ret = await sha.sigOfDeal(acct4, 0);
    console.log("sigOfDeal: ", ret);


    ret = await sha.established();
    console.log("SHA established: ", ret);


    await gk.effectiveSHA(sha.address, {
        from: accounts[2]
    });

    events = await boh.getPastEvents("UpdateStateOfDoc");
    console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);

    events = await boh.getPastEvents("ChangePointer");
    console.log("Event 'ChangePointer': ", events[0].returnValues);

    callback();
}