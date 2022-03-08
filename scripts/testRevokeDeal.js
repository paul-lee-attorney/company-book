const Bookeeper = artifacts.require("Bookeeper");
const Agreement = artifacts.require("Agreement");
const BookOfMotions = artifacts.require("BookOfMotions");


module.exports = async function (callback) {

    const bookeeper = await Bookeeper.deployed();
    console.log("bookeeper address: ", bookeeper.address);

    const bom = await BookOfMotions.deployed();
    console.log("bookOfMotions: ", bom.address);

    const accounts = await web3.eth.getAccounts();
    console.log(accounts);

    // 创建IA
    let receipt = await bookeeper.createIA("2", {
        from: accounts[8]
    });

    let add = receipt.logs[0].address;

    const ia1 = await Agreement.at(add);

    console.log("InvestmentAgreement Address: ", ia1.address);

    // 设定 Attorney
    await ia1.setAttorney(accounts[7], {
        from: accounts[8]
    });

    let attorney = await ia1.getAttorney();
    console.log("Attorney to IA is: ", attorney);

    // 确定IA签署方
    await ia1.addPartyToDoc(accounts[8], {
        from: accounts[7]
    });

    await ia1.addPartyToDoc(accounts[9], {
        from: accounts[7]
    });

    let qtyOfParties = await ia1.qtyOfParties({
        from: accounts[7]
    });
    console.log("Qty of parties of IA: ", qtyOfParties);

    // 设定签署和生效截止期
    await ia1.setClosingDeadline("1648592606", {
        from: accounts[7]
    });
    await ia1.setSigDeadline("1647002800", {
        from: accounts[7]
    });

    let closingDeadline = await ia1.closingDeadline({
        from: accounts[7]
    });
    console.log("closingDeadline of IA: ", closingDeadline);

    let sigDeadline = await ia1.sigDeadline({
        from: accounts[7]
    });
    console.log("sigDeadline of IA :", sigDeadline);


    let closingDate = Math.floor(Date.now() + 30);
    console.log("closingDate: ", closingDate);

    // 股转交易
    await ia1.setDeal("0", "6", "0", accounts[8], accounts[9], "12000", "1000000", "1000000", closingDate.toString(), {
        from: accounts[7]
    });

    console.log("Deal set out");

    // 定稿IA
    await ia1.finalizeIA({
        from: accounts[7]
    });

    console.log("IA finalized");

    // 分发IA（创建股东）
    await ia1.circulateDoc({
        from: accounts[8]
    });

    console.log("IA circulated");


    // 签署IA
    await ia1.signDoc({
        from: accounts[8]
    });
    await ia1.signDoc({
        from: accounts[9]
    });

    console.log("IA established");

    // 提交IA
    await bookeeper.submitIA(ia1.address, "0x38301fb0b5fcf3aaa4b97c4771bb6c75546e313b4ce7057c51a8cc6a3ace9d7e", {
        from: accounts[8]
    });

    console.log("IA submitted");

    // 卖方提交表决
    await bookeeper.proposeMotion(ia1.address, {
        from: accounts[8]
    });

    console.log("motion of IA submitted");

    // 股东表决
    await bom.supportMotion(ia1.address, {
        from: accounts[2]
    });

    await bom.supportMotion(ia1.address, {
        from: accounts[3]
    });

    await bom.supportMotion(ia1.address, {
        from: accounts[4]
    });

    await bom.againstMotion(ia1.address, {
        from: accounts[5]
    });

    await bom.supportMotion(ia1.address, {
        from: accounts[8]
    });


    console.log("motion is voted");

    // 统计表决结果
    await bom.voteCounting(ia1.address, {
        from: accounts[8]
    });

    console.log("motion is passed");

    // 卖方确认CP成就
    await bookeeper.pushToCoffer("0", ia1.address, "0xa0901f1cd5c43406903d4c99948473e2d7d726ad704aaf6abf6184ea35c70f26", "0", {
        from: accounts[8]
    });

    console.log("share pushed into coffer");

    let strKey = "peace is not free";

    setTimeout(function () {
        bookeeper.revokeDeal("0", ia1.address, strKey, {
            from: accounts[8]
        });
    }, 30000);

    console.log("deal is revoked");

    callback();
}