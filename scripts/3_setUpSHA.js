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
    console.log("Event 'SetRule': ", events[0].returnValues);

    // ==== ST_Ext ====
    await sha.setRule(2, 0, 0, 5000, 1, 1, 1, 1, 1, 1, 0, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetRule");
    console.log("Event 'SetRule': ", events[0].returnValues);

    // ==== ST_Int ====
    await sha.setRule(3, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, {
        from: accounts[7]
    });
    events = await sha.getPastEvents("SetRule");
    console.log("Event 'SetRule': ", events[0].returnValues);

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


    await fr.setFirstRefusal(3, 1, 1, 1, {
        from: accounts[7]
    });
    let rule = await fr.ruleOfFR(3)
    console.log("set FR for external transfer: ", rule);

    await fr.setFirstRefusal(1, 1, 1, 1, {
        from: accounts[7]
    });
    rule = await fr.ruleOfFR(1)
    console.log("set FR for capital increase: ", rule);

    await fr.lockContents({
        from: accounts[7]
    });
    console.log("FR contents have been locked. ");

    await sha.finalizeDoc({
        from: accounts[7]
    });
    console.log("SHA finalized.");

    await gk.circulateSHA(sha.address, {
        from: accounts[2]
    });
    console.log("SHA circulated.");

    await gk.signSHA(sha.address, "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85", {
        from: accounts[2]
    });
    console.log("acct2 signed SHA.");

    await gk.signSHA(sha.address, "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85", {
        from: accounts[3]
    });
    console.log("acct3 signed SHA.");

    await gk.signSHA(sha.address, "0x49893d3f1021aa92c3103b3901e47aeb766de80f8c731731424df8f70ecc0d85", {
        from: accounts[4]
    });
    console.log("acct4 signed SHA.");

    await gk.effectiveSHA(sha.address, {
        from: accounts[2]
    });
    console.log("SHA effectivated.");

    // const bohKeeper = BOHKeeper.deployed();
    // console.log("BOHKeeper: ", bohKeeper.address);

    // const boh = BOH.deployed();
    // console.log("BOH: ", boh.address);


    // // 确定SHA签署方
    // await sha1.addPartyToDoc(accounts[2], {
    //     from: accounts[7]
    // });

    // await sha1.addPartyToDoc(accounts[3], {
    //     from: accounts[7]
    // });
    // await sha1.addPartyToDoc(accounts[4], {
    //     from: accounts[7]
    // });
    // await sha1.addPartyToDoc(accounts[5], {
    //     from: accounts[7]
    // });

    // let qtyOfParties = await sha1.qtyOfParties({
    //     from: accounts[7]
    // });
    // console.log("Qty of parties of SHA: ", qtyOfParties);

    // // 设定签署和生效截止期
    // await sha1.setClosingDeadline("1648592606", {
    //     from: accounts[7]
    // });
    // await sha1.setSigDeadline("1647087806", {
    //     from: accounts[7]
    // });

    // let closingDeadline = await sha1.closingDeadline({
    //     from: accounts[7]
    // });
    // console.log("closingDeadline of SHA: ", closingDeadline);

    // let sigDeadline = await sha1.sigDeadline({
    //     from: accounts[7]
    // });
    // console.log("sigDeadline :", sigDeadline);


    // // 起草SHA条款

    // // LockUp

    // let templates = await sha1.tempOfTitle("0", {
    //     from: accounts[2]
    // });

    // console.log("Template of LuckUp:", templates);

    // receipt = await sha1.createTerm("0", {
    //     from: accounts[7]
    // });

    // add = receipt.logs[0].address;
    // console.log("Term of LockUp: ", add);

    // let lu1 = await LockUp.at(add);
    // // sha1.getTerm("0");

    // // 设定项目律师
    // await lu1.setAttorney(accounts[7], {
    //     from: accounts[7]
    // });

    // attorney = await lu1.getAttorney();

    // console.log("Attorney to LockUp: ", attorney);

    // // 起草条款
    // receipt = await lu1.setLocker("1", "1647354190", {
    //     from: accounts[7]
    // });

    // // console.log(receipt);

    // receipt = await lu1.addKeyholder("1", accounts[3], {
    //     from: accounts[7]
    // });

    // // console.log(receipt);

    // receipt = await lu1.addKeyholder("1", accounts[4], {
    //     from: accounts[7]
    // });

    // // console.log(receipt);

    // receipt = await lu1.addKeyholder("1", accounts[5], {
    //     from: accounts[7]
    // });

    // // console.log(receipt);

    // // VotingRules
    // receipt = await sha1.createTerm("14", {
    //     from: accounts[7]
    // });

    // add = receipt.logs[0].address;

    // let vr1 = await VotingRules.at(add);
    // await vr1.setAttorney(accounts[7], {
    //     from: accounts[7]
    // });

    // console.log("VotingRules :", vr1.address);

    // await vr1.setRule("1", "0", "6667", "false", "false", "false", "5", {
    //     from: accounts[7]
    // });

    // await vr1.setRule("2", "5001", "0", "false", "false", "true", "5", {
    //     from: accounts[7]
    // });

    // await vr1.setCommonRules("7", "false", {
    //     from: accounts[7]
    // });

    // await vr1.getRule("2", {
    //     from: accounts[7]
    // });
    // // console.log("ShareTransfer Rule: ", stRule);

    // // 设定 增资、股转 审查条款



    // // 定稿SHA
    // await sha1.finalizeSHA({
    //     from: accounts[7]
    // });

    // console.log("SHA finalized");

    // // 分发SHA（创建股东）
    // await sha1.circulateDoc({
    //     from: accounts[2]
    // });

    // console.log("SHA circulated");


    // // 签署SHA
    // await sha1.signDoc({
    //     from: accounts[2]
    // });
    // await sha1.signDoc({
    //     from: accounts[3]
    // });
    // await sha1.signDoc({
    //     from: accounts[4]
    // });
    // await sha1.signDoc({
    //     from: accounts[5]
    // });

    // console.log("SHA established");

    // // 提交SHA
    // await bookeeper.submitSHA(sha1.address, "0x38301fb0b5fcf3aaa4b97c4771bb6c75546e313b4ce7057c51a8cc6a3ace9d7e", {
    //     from: accounts[2]
    // });

    // console.log("SHA submitted");

    // // 设定SHA为生效版本
    // await bookeeper.effectiveSHA(sha1.address, {
    //     from: accounts[2]
    // });

    // console.log("the One:", sha1.address);

    callback();
}