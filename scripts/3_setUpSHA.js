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

    let sha = await SHA.deployed();
    console.log("SHA: ", sha.address)

    // ==== set template of SHA ====

    await gk.setTempOfSHA(sha.address, 0, {
        from: accounts[1]
    });
    let events = await boh.getPastEvents("SetTemplate");
    console.log("Event 'SetTemplate': ", events[0].returnValues);

    // ==== 创建SHA ====

    let ret = await gk.createSHA(0, {
        from: accounts[2]
    });

    events = await boh.getPastEvents("UpdateStateOfDoc");
    console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);

    let addr = ret.logs[0].address;
    console.log("addr of SHA: ", addr);

    sha = await SHA.at(addr);
    console.log("get SHA: ", sha.address);

    events = await sha.getPastEvents("SetRegCenter");
    console.log("Event 'SetRegCenter': ", events[0].returnValues);

    events = await sha.getPastEvents("SetGeneralKeeper");
    console.log("Event 'SetGeneralKeeper': ", events[0].returnValues);

    events = await sha.getPastEvents("Init");
    console.log("Event 'Init': ", events[0].returnValues);

    events = await sha.getPastEvents("SetBOA");
    console.log("Event 'SetBOA': ", events[0].returnValues);

    events = await sha.getPastEvents("SetBOH");
    console.log("Event 'SetBOH': ", events[0].returnValues);

    events = await sha.getPastEvents("SetBOS");
    console.log("Event 'SetBOS': ", events[0].returnValues);

    events = await sha.getPastEvents("SetROM");
    console.log("Event 'SetROM': ", events[0].returnValues);

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

    events = await sha.getPastEvents("AddBlank");
    console.log("Event 'AddBlank' : ", events[0].returnValues);

    await sha.addParty(acct3, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("AddBlank");
    console.log("Event 'AddBlank' : ", events[0].returnValues);

    await sha.addParty(acct4, {
        from: accounts[7]
    });

    events = await sha.getPastEvents("AddBlank");
    console.log("Event AddBlank", events[0].returnValues);

    await sha.addParty(acct5, {
        from: accounts[7]
    });

    events = await sha.getPastEvents("AddBlank");
    console.log("Event 'AddBlank' : ", events[0].returnValues);

    await sha.removeBlank(acct5, 0, {
        from: accounts[7]
    });

    events = await sha.getPastEvents("RemoveBlank");
    console.log("Event 'RemoveBlank': ", events[0].returnValues);

    // ==== GoverningRules ====

    let basedOnPar = '00';
    let proposalThreshold = '03e8';
    let maxNumOfDirectors = '03';
    let tenureOfBoard = '03';
    let rule = '0x' + basedOnPar + proposalThreshold + maxNumOfDirectors + tenureOfBoard + '0000000004' + '0000000005';

    rule = web3.utils.padRight(rule, 64);

    await sha.setGovernanceRule(rule, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetGovernanceRule");
    console.log("Event 'SetGovernanceRule': ", events[0].returnValues);

    ret = await sha.basedOnPar();
    console.log("Event 'basedOnPar': ", ret.toNumber());

    ret = await sha.proposalThreshold();
    console.log("Event 'proposalThreshold': ", ret.toNumber());

    ret = await sha.maxNumOfDirectors();
    console.log("Event 'maxNumOfDirectors': ", ret.toNumber());

    ret = await sha.tenureOfBoard();
    console.log("Event 'tenureOfBoard': ", ret.toNumber());

    ret = await sha.appointerOfChairman();
    console.log("Event 'appointerOfChairman': ", ret.toNumber());

    ret = await sha.appointerOfViceChairman();
    console.log("Event 'appointerOfViceChairman': ", ret.toNumber());

    // ==== CI VotingRule ====

    let ratioHead = '0000';
    let ratioAmount = '1a0a';
    let onlyAttendance = '00';
    let impliedConsent = '00';
    let partyAsConsent = '01';
    let againstShallBuy = '00';
    let reviewDays = '0f';
    let votingDays = '1e';
    let execDaysForPutOpt = '07';
    let typeOfVote = '01';
    let vetoHolder = '0000000000';

    rule = '0x' + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + reviewDays + votingDays + execDaysForPutOpt + typeOfVote + vetoHolder;

    rule = web3.utils.padRight(rule, 64);

    await sha.setVotingRule(rule, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetVotingRule");
    console.log("Event 'SetVotingRule' for CI: ", events[0].returnValues);

    ret = await sha.votingRules(1);
    console.log("VotingRules for typeOfVote: ", typeOfVote, " rule: ", rule);

    // ==== SText VotingRule ====

    ratioHead = '0000';
    ratioAmount = '1388';
    onlyAttendance = '00';
    impliedConsent = '01';
    partyAsConsent = '01';
    againstShallBuy = '01';
    reviewDays = '0f';
    votingDays = '1e';
    execDaysForPutOpt = '07';
    typeOfVote = '02';
    vetoHolder = '0000000000';

    rule = '0x' + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + reviewDays + votingDays + execDaysForPutOpt + typeOfVote + vetoHolder;

    rule = web3.utils.padRight(rule, 64);

    await sha.setVotingRule(rule, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetVotingRule");
    console.log("Event 'SetVotingRule' for SText: ", events[0].returnValues);

    ret = await sha.votingRules(2);
    console.log("VotingRules for typeOfVote: ", typeOfVote, " rule: ", rule);

    // ==== STint ====

    ratioHead = '0000';
    ratioAmount = '0000';
    onlyAttendance = '00';
    impliedConsent = '01';
    partyAsConsent = '01';
    againstShallBuy = '01';
    reviewDays = '0f';
    votingDays = '1e';
    execDaysForPutOpt = '07';
    typeOfVote = '03';
    vetoHolder = '0000000000';

    rule = '0x' + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + reviewDays + votingDays + execDaysForPutOpt + typeOfVote + vetoHolder;

    rule = web3.utils.padRight(rule, 64);

    await sha.setVotingRule(rule, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetVotingRule");
    console.log("Event 'SetVotingRule' for STint: ", events[0].returnValues);

    ret = await sha.votingRules(3);
    console.log("VotingRules for typeOfVote: ", typeOfVote, " rule: ", rule);

    // ==== CI & STint ====

    ratioHead = '0000';
    ratioAmount = '1a0a';
    onlyAttendance = '00';
    impliedConsent = '00';
    partyAsConsent = '01';
    againstShallBuy = '00';
    reviewDays = '0f';
    votingDays = '1e';
    execDaysForPutOpt = '07';
    typeOfVote = '04';
    vetoHolder = '0000000000';

    rule = '0x' + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + reviewDays + votingDays + execDaysForPutOpt + typeOfVote + vetoHolder;

    rule = web3.utils.padRight(rule, 64);

    await sha.setVotingRule(rule, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetVotingRule");
    console.log("Event 'SetVotingRule' for STint: ", events[0].returnValues);

    ret = await sha.votingRules(4);
    console.log("VotingRules for typeOfVote: ", typeOfVote, " rule: ", rule);

    // ==== SText & STint ====

    ratioHead = '0000';
    ratioAmount = '1388';
    onlyAttendance = '00';
    impliedConsent = '01';
    partyAsConsent = '01';
    againstShallBuy = '01';
    reviewDays = '0f';
    votingDays = '1e';
    execDaysForPutOpt = '07';
    typeOfVote = '05';
    vetoHolder = '0000000000';

    rule = '0x' + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + reviewDays + votingDays + execDaysForPutOpt + typeOfVote + vetoHolder;

    rule = web3.utils.padRight(rule, 64);

    await sha.setVotingRule(rule, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetVotingRule");
    console.log("Event 'SetVotingRule' for STint: ", events[0].returnValues);

    ret = await sha.votingRules(5);
    console.log("VotingRules for typeOfVote: ", typeOfVote, " rule: ", rule);

    // ==== CI & SText & STint ====

    ratioHead = '0000';
    ratioAmount = '1a0a';
    onlyAttendance = '00';
    impliedConsent = '00';
    partyAsConsent = '01';
    againstShallBuy = '00';
    reviewDays = '0f';
    votingDays = '1e';
    execDaysForPutOpt = '07';
    typeOfVote = '06';
    vetoHolder = '0000000000';

    rule = '0x' + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + reviewDays + votingDays + execDaysForPutOpt + typeOfVote + vetoHolder;

    rule = web3.utils.padRight(rule, 64);

    await sha.setVotingRule(rule, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetVotingRule");
    console.log("Event 'SetVotingRule' for STint: ", events[0].returnValues);

    ret = await sha.votingRules(6);
    console.log("VotingRules for typeOfVote: ", typeOfVote, " rule: ", rule);

    // ==== CI & SText ====

    ratioHead = '0000';
    ratioAmount = '1a0a';
    onlyAttendance = '00';
    impliedConsent = '00';
    partyAsConsent = '01';
    againstShallBuy = '00';
    reviewDays = '0f';
    votingDays = '1e';
    execDaysForPutOpt = '07';
    typeOfVote = '07';
    vetoHolder = '0000000000';

    rule = '0x' + ratioHead + ratioAmount + onlyAttendance + impliedConsent + partyAsConsent + againstShallBuy + reviewDays + votingDays + execDaysForPutOpt + typeOfVote + vetoHolder;

    rule = web3.utils.padRight(rule, 64);

    await sha.setVotingRule(rule, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetVotingRule");
    console.log("Event 'SetVotingRule' for STint: ", events[0].returnValues);

    ret = await sha.votingRules(7);
    console.log("VotingRules for typeOfVote: ", typeOfVote, " rule: ", rule);

    // ==== FR ====
    addr = await sha.createTerm.call(3, {
        from: accounts[7]
    });

    let fr = await FR.at(addr);
    console.log("get FR: ", fr.address);

    events = await fr.getPastEvents("Init");
    console.log("Event 'Init': ", events[0].returnValues);

    events = await rc.getPastEvents("SetManager");
    console.log("Event 'SetManager': ", events[0].returnValues);

    events = await fr.getPastEvents("SetBOM");
    console.log("Event 'SetBOM': ", events[0].returnValues);

    events = await fr.getPastEvents("SetROM");
    console.log("Event 'SetROM': ", events[0].returnValues);

    events = await sha.getPastEvents("CreateTerm");
    console.log("Event 'CreateTerm': ", events[0].returnValues);

    // ==== remove FR ====
    await sha.removeTerm(3, {
        from: accounts[7]
    });

    events = await sha.getPastEvents("RemoveTerm");
    console.log("Event 'RemoveTerm': ", events[0].returnValues);

    // ==== Set FR as per company law of China ====

    addr = await sha.createTerm.call(3, {
        from: accounts[7]
    });

    fr = await FR.at(addr);
    console.log("get FR: ", fr.address);

    events = await fr.getPastEvents("Init");
    console.log("Event 'Init': ", events[0].returnValues);

    // ==== FR rule for CI ====

        // struct ruleInfo {
        //     uint8 typeOfDeal; 1-CI; 2-ST(ext); 3-ST(int);
        //     bool membersEqual;
        //     bool proRata;
        //     bool basedOnPar;
        // }

    rule = '0x' + '01' + '01' + '01' + '00';
    rule = web3.utils.padRight(rule, 64);

    await fr.setFirstRefusal(rule, {
        from: accounts[7]
    });

    events = await fr.getPastEvents("SetFirstRefusal");
    console.log("Event 'SetFirstRefusal': ", events[0].returnValues);

    // ==== FR rule for SText ====

        // struct ruleInfo {
        //     uint8 typeOfDeal; 1-CI; 2-ST(ext); 3-ST(int);
        //     bool membersEqual;
        //     bool proRata;
        //     bool basedOnPar;
        // }

    rule = '0x' + '02' + '01' + '01' + '00';
    rule = web3.utils.padRight(rule, 64);

    await fr.setFirstRefusal(rule, {
        from: accounts[7]
    });

    events = await fr.getPastEvents("SetFirstRefusal");
    console.log("Event 'SetFirstRefusal': ", events[0].returnValues);

    await fr.delFirstRefusal(2, {
        from: accounts[7]
    });

    events = await fr.getPastEvents("DelFirstRefusal");
    console.log("Event 'DelFirstRefusal': ", events[0].returnValues);



    // events = await fr.getPastEvents("SetFirstRefusal");
    // console.log("Event 'SetFirstRefusal' for ST_Ext: ", events[0].returnValues);

    // await fr.delFirstRefusal(2, {
    //     from: accounts[7]
    // });

    // events = await fr.getPastEvents("DelFirstRefusal");
    // console.log("Event 'DelFirstRefusal' for ST_Ext: ", events[0].returnValues);

    // await fr.setFirstRefusal(2, 1, 1, 0, {
    //     from: accounts[7]
    // });

    // events = await fr.getPastEvents("SetFirstRefusal");
    // console.log("Event 'SetFirstRefusal' for ST_Ext: ", events[0].returnValues);

    // await fr.setFirstRefusal(1, 1, 1, 0, {
    //     from: accounts[7]
    // });

    // events = await fr.getPastEvents("SetFirstRefusal");
    // console.log("Event 'SetFirstRefusal' for CI: ", events[0].returnValues);


    // rule = await fr.ruleOfFR(1)
    // console.log("FR for CI: ", rule);

    // await fr.lockContents({
    //     from: accounts[7]
    // });

    // events = await rc.getPastEvents("AbandonRole");
    // console.log("Event 'AbandonRole': ", events[0].returnValues);

    // events = await rc.getPastEvents("SetManager");
    // console.log("Event 'SetManager': ", events[0].returnValues);

    // events = await fr.getPastEvents("LockContents");
    // console.log("Event 'LockContents': ", events[0].returnValues);



    // // ==== 设定签署和生效截止期 =====
    // let cur = null;

    // // cur = Date.parse(new Date()) / 1000;
    // cur = await web3.eth.getBlock("latest");

    // await sha.setSigDeadline(cur.timestamp + 86400, {
    //     from: accounts[7]
    // });

    // events = await sha.getPastEvents("SetSigDeadline");
    // console.log("Event 'SetSigDeadline': ", events[0].returnValues);

    // await sha.setClosingDeadline(cur.timestamp + 86400, {
    //     from: accounts[7]
    // });

    // events = await sha.getPastEvents("SetClosingDeadline");
    // console.log("Event 'SetClosingDeadline': ", events[0].returnValues);

    // let closingDeadline = await sha.closingDeadline({
    //     from: accounts[7]
    // });
    // console.log("closingDeadline of SHA: ", closingDeadline);

    // let sigDeadline = await sha.sigDeadline({
    //     from: accounts[7]
    // });
    // console.log("sigDeadline :", sigDeadline);

    // // ==== SHA finalizeDoc ====

    // await sha.finalizeDoc({
    //     from: accounts[7]
    // });

    // events = await rc.getPastEvents("AbandonRole");
    // console.log("Event 'AbandonRole': ", events[0].returnValues);

    // events = await rc.getPastEvents("SetManager");
    // console.log("Event 'SetManager': ", events[0].returnValues);

    // events = await sha.getPastEvents("LockContents");
    // console.log("Event 'LockContents': ", events[0].returnValues);

    // events = await sha.getPastEvents("DocFinalized");
    // console.log("Event 'DocFinalized': ", events[0].returnValues);

    // // ==== CirculateSHA ====

    // await gk.circulateSHA(sha.address, {
    //     from: accounts[2]
    // });

    // events = await rc.getPastEvents("SetManager");
    // console.log("Event 'SetManager': ", events[0].returnValues);

    // events = await boh.getPastEvents("UpdateStateOfDoc");
    // console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);



    // // ==== Signe SHA ====

    // await gk.signSHA(sha.address, "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85", {
    //     from: accounts[2]
    // });

    // events = await sha.getPastEvents("SignDeal");
    // console.log("Event 'SignDeal': ", events[0].returnValues);

    // // events = await sha.getPastEvents("DocEstablished");
    // // console.log("Event 'DocEstablished': ", events[0].returnValues);

    // await gk.signSHA(sha.address, "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85", {
    //     from: accounts[3]
    // });

    // events = await sha.getPastEvents("SignDeal");
    // console.log("Event 'SignDeal': ", events[0].returnValues);

    // await gk.signSHA(sha.address, "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85", {
    //     from: accounts[4]
    // });

    // events = await sha.getPastEvents("SignDeal");
    // console.log("Event 'SignDeal': ", events[0].returnValues);

    // events = await sha.getPastEvents("DocEstablished");
    // console.log("Event 'DocEstablished': ", events[0].returnValues);


    // await gk.effectiveSHA(sha.address, {
    //     from: accounts[2]
    // });

    // events = await boh.getPastEvents("UpdateStateOfDoc");
    // console.log("Event 'UpdateStateOfDoc': ", events[0].returnValues);

    // events = await boh.getPastEvents("ChangePointer");
    // console.log("Event 'ChangePointer': ", events[0].returnValues);

    // console.log("SHA effectivated.");

    // // ==== Query ====

    // let res = null;

    // res = await sha.tempOfTitle(3);
    // console.log("FirstRefusal Template: ", res);

    // res = await sha.hasTitle(3);
    // console.log("Has FR term? ", res);

    // res = await sha.isTitle(3);
    // console.log("isTitle: ", res);

    // res = await sha.isBody(fr.address);
    // console.log("isBody: ", res);

    // res = await sha.titles();
    // console.log("titles: ", res.map(v => v.toNumber()));

    // res = await sha.bodies();
    // console.log("bodies: ", res);

    // res = await sha.getTerm(3);
    // console.log("getTerm FR: ", res);

    // res = await sha.votingRules(2);
    // console.log("votingRules: ", res);

    // res = await sha.basedOnPar();
    // console.log("basedOnPar: ", res);

    // res = await sha.proposalThreshold();
    // console.log("proposalThreshold: ", res.toNumber());

    // res = await sha.maxNumOfDirectors();
    // console.log("maxNumOfDirectors: ", res.toNumber());

    // res = await sha.tenureOfBoard();
    // console.log("tenureOfBoard: ", res.toNumber());

    callback();
}