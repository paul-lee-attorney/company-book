const BOS = artifacts.require("BookOfShares");
const BOM = artifacts.require("BookOfMotions");

const BOAKeeper = artifacts.require("BOAKeeper");

const GK = artifacts.require("GeneralKeeper");
const IA = artifacts.require("InvestmentAgreement");
const RC = artifacts.require("RegCenter");

module.exports = async function (callback) {

    const gk = await GK.deployed();
    console.log("GeneralKeeper address: ", gk.address);

    const boaKeeper = await BOAKeeper.deployed();
    console.log("BOAKeeper address: ", boaKeeper.address);

    const accounts = await web3.eth.getAccounts();
    console.log(accounts);

    // 创建IA
    let receipt = await gk.createIA("0", {
        from: accounts[2]
    });

    let addr = receipt.logs[0].address;

    console.log("IA address: ", addr);

    const ia = await IA.at(addr);
    console.log("get ia: ", ia.address);

    // 设定 GeneralCounsel
    await ia.setManager(2, accounts[2], accounts[7], {
        from: accounts[2]
    });

    let attorney = await ia.getManager("2");
    console.log("GC to IA is: ", attorney.toNumber());

    // 设定签署和生效截止期(22-10-19)
    await ia.setClosingDeadline("1666187404", {
        from: accounts[7]
    });
    await ia.setSigDeadline("1666187404", {
        from: accounts[7]
    });

    let closingDeadline = await ia.closingDeadline({
        from: accounts[7]
    });
    console.log("closingDeadline of IA: ", closingDeadline.toNumber());

    let sigDeadline = await ia.sigDeadline({
        from: accounts[7]
    });
    console.log("sigDeadline of IA :", sigDeadline.toNumber());

    const rc = await RC.deployed();

    let acct5 = await rc.userNo(accounts[5]);


    // 股转交易
    const bos = await BOS.deployed();

    let share1 = await bos.getShare(1);

    await ia.createDeal(3, share1.shareNumber, "0", acct5.toNumber(), 5, 0, {
        from: accounts[7]
    });
    console.log("deal crated.");

    确定IA签署方
    await ia.addParty(accounts[2], {
        from: accounts[7]
    });

    await ia.addParty(accounts[5], {
        from: accounts[7]
    });

    // 验证IA当事方
    let qtyOfParties = await ia.qtyOfParties({
        from: accounts[7]
    });
    console.log("Qty of parties of IA: ", qtyOfParties.toNumber());

    let parties = await ia.parties();
    parties.forEach(item => console.log(item.toNumber()));

    // 定稿IA
    await ia.finalizeDoc({
        from: accounts[7]
    });
    console.log("IA finalized");

    // 分发IA（ 创建股东）
    await gk.circulateIA(ia.address, {
        from: accounts[2]
    });
    console.log("IA circulated");

    // 签署SHA
    await gk.signIA(ia.address, "0xd3cbe222ebe6a7fa1dc87ecc76555c40943e8ec1f6a91c5cf479509accb1ef5a", {
        from: accounts[2]
    });
    console.log("acct2 signed IA.")
    await gk.signIA(ia.address, "0xe5b0e7ffcb90dc5ee09f49282b47da64e12e0b36c689866cb8363f0be8027ffb", {
        from: accounts[5]
    });
    console.log("acct5 signed IA.")

    let established = await ia.established();
    console.log("IA's established flag: ", established);

    // 提交IA
    // 测试时，需要注释掉BOMKeeper 75-79行
    await gk.proposeMotion(ia.address, {
        from: accounts[2]
    });
    console.log("IA proposed.");

    // 提交IA
    await gk.castVote(ia.address, 1, "0xe5b0e7ffcb90dc5ee09f49282b47da64e12e0b36c689866cb8363f0be8027ffb", {
        from: accounts[3]
    });
    console.log("acct3 vote yea.");

    await gk.castVote(ia.address, 1, "0xe5b0e7ffcb90dc5ee09f49282b47da64e12e0b36c689866cb8363f0be8027ffb", {
        from: accounts[4]
    });
    console.log("acct4 vote yea.");

    // 测试时，注释BOM 第 200 行
    await gk.voteCounting(ia.address, {
        from: accounts[2]
    });
    console.log("vote counted.");

    const bom = await BOM.deployed();
    let flag = await bom.isPassed(ia.address);
    console.log("motion is passed? ", flag.toString());

    callback();
}