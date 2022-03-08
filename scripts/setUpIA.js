const Bookeeper = artifacts.require("Bookeeper");
const Agreement = artifacts.require("Agreement");
// const LockUp = artifacts.require("LockUp");
// const VotingRules = artifacts.require("VotingRules");

module.exports = async function (callback) {

    const bookeeper = await Bookeeper.deployed();
    console.log("bookeeper address: ", bookeeper.address);
    const accounts = await web3.eth.getAccounts();
    console.log(accounts);

    // 创建IA
    let receipt = await bookeeper.createIA("2", {
        from: accounts[2]
    });

    let add = receipt.logs[0].address;

    // console.log("IA address: ", add);

    const ia1 = await Agreement.at(add);

    console.log("InvestmentAgreement Address: ", ia1.address);

    // 设定 Attorney
    await ia1.setAttorney(accounts[7], {
        from: accounts[2]
    });

    let attorney = await ia1.getAttorney();
    console.log("Attorney to IA is: ", attorney);

    // 确定IA签署方
    await ia1.addPartyToDoc(accounts[2], {
        from: accounts[7]
    });

    await ia1.addPartyToDoc(accounts[8], {
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

    // 股转交易
    await ia1.setDeal("0", "1", "0", accounts[2], accounts[8], "12000", "1000000", "1000000", "1647092606", {
        from: accounts[7]
    });

    console.log("IA finalized");

    // 定稿IA
    await ia1.finalizeIA({
        from: accounts[7]
    });

    console.log("IA finalized");

    // 分发IA（创建股东）
    await ia1.circulateDoc({
        from: accounts[2]
    });

    console.log("IA circulated");


    // 签署SHA
    await ia1.signDoc({
        from: accounts[2]
    });
    await ia1.signDoc({
        from: accounts[8]
    });

    console.log("IA established");

    // 提交IA
    await bookeeper.submitIA(ia1.address, "0x38301fb0b5fcf3aaa4b97c4771bb6c75546e313b4ce7057c51a8cc6a3ace9d7e", {
        from: accounts[2]
    });

    console.log("IA submitted");

    callback();
}