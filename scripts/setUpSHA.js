const Bookeeper = artifacts.require("Bookeeper");
const ShareholdersAgreement = artifacts.require("ShareholdersAgreement");
const LockUp = artifacts.require("LockUp");
const VotingRules = artifacts.require("VotingRules");

module.exports = async function (callback) {

    const bookeeper = await Bookeeper.deployed();
    const accounts = await web3.eth.getAccounts();
    console.log(accounts);

    // 创建SHA
    let receipt = await bookeeper.createSHA("2", {
        from: accounts[2]
    });

    let add = receipt.logs[0].address;

    console.log(add);

    const sha1 = await ShareholdersAgreement.at(add);

    console.log("ShareholdersAgreement Address: ", sha1.address);

    // 设定 Attorney
    await sha1.setAttorney(accounts[7], {
        from: accounts[2]
    });

    let attorney = await sha1.getAttorney();
    console.log("Attorney to SHA is: ", attorney);

    // 确定SHA签署方
    await sha1.addPartyToDoc(accounts[2], {
        from: accounts[7]
    });

    await sha1.addPartyToDoc(accounts[3], {
        from: accounts[7]
    });
    await sha1.addPartyToDoc(accounts[4], {
        from: accounts[7]
    });
    await sha1.addPartyToDoc(accounts[5], {
        from: accounts[7]
    });

    let qtyOfParties = await sha1.qtyOfParties({
        from: accounts[7]
    });
    console.log("Qty of parties of SHA: ", qtyOfParties);

    // 设定签署和生效截止期
    await sha1.setClosingDeadline("1648592606", {
        from: accounts[7]
    });
    await sha1.setSigDeadline("1647087806", {
        from: accounts[7]
    });

    let closingDeadline = await sha1.closingDeadline({
        from: accounts[7]
    });
    console.log("closingDeadline of SHA: ", closingDeadline);

    let sigDeadline = await sha1.sigDeadline({
        from: accounts[7]
    });
    console.log("sigDeadline :", sigDeadline);


    // 起草SHA条款

    // LockUp

    let templates = await sha1.tempOfTitle("0", {
        from: accounts[2]
    });

    console.log("Template of LuckUp:", templates);

    receipt = await sha1.createTerm("0", {
        from: accounts[7]
    });

    add = receipt.logs[0].address;
    console.log("Term of LockUp: ", add);

    let lu1 = await LockUp.at(add);
    // sha1.getTerm("0");

    // 设定项目律师
    await lu1.setAttorney(accounts[7], {
        from: accounts[7]
    });

    attorney = await lu1.getAttorney();

    console.log("Attorney to LockUp: ", attorney);

    // 起草条款
    receipt = await lu1.setLocker("1", "1647354190", {
        from: accounts[7]
    });

    // console.log(receipt);

    receipt = await lu1.addKeyholder("1", accounts[3], {
        from: accounts[7]
    });

    // console.log(receipt);

    receipt = await lu1.addKeyholder("1", accounts[4], {
        from: accounts[7]
    });

    // console.log(receipt);

    receipt = await lu1.addKeyholder("1", accounts[5], {
        from: accounts[7]
    });

    // console.log(receipt);

    // VotingRules
    receipt = await sha1.createTerm("14", {
        from: accounts[7]
    });

    add = receipt.logs[0].address;

    let vr1 = await VotingRules.at(add);
    await vr1.setAttorney(accounts[7], {
        from: accounts[7]
    });

    console.log("VotingRules :", vr1.address);

    await vr1.setRule("1", "0", "6667", "false", "false", "false", "5", {
        from: accounts[7]
    });

    await vr1.setRule("2", "5001", "0", "false", "false", "true", "5", {
        from: accounts[7]
    });

    await vr1.setCommonRules("7", "false", {
        from: accounts[7]
    });

    await vr1.getRule("2", {
        from: accounts[7]
    });
    // console.log("ShareTransfer Rule: ", stRule);

    // 设定 增资、股转 审查条款



    // 定稿SHA
    await sha1.finalizeSHA({
        from: accounts[7]
    });

    console.log("SHA finalized");

    // 分发SHA（创建股东）
    await sha1.circulateDoc({
        from: accounts[2]
    });

    console.log("SHA circulated");


    // 签署SHA
    await sha1.signDoc({
        from: accounts[2]
    });
    await sha1.signDoc({
        from: accounts[3]
    });
    await sha1.signDoc({
        from: accounts[4]
    });
    await sha1.signDoc({
        from: accounts[5]
    });

    console.log("SHA established");

    // 提交SHA
    await bookeeper.submitSHA(sha1.address, "0x38301fb0b5fcf3aaa4b97c4771bb6c75546e313b4ce7057c51a8cc6a3ace9d7e", {
        from: accounts[2]
    });

    console.log("SHA submitted");

    // 设定SHA为生效版本
    await bookeeper.effectiveSHA(sha1.address, {
        from: accounts[2]
    });

    console.log("the One:", sha1.address);

    callback();
}