const Bookeeper = artifacts.require("Bookeeper");
const Agreement = artifacts.require("Agreement");
const BookOfMotions = artifacts.require("BookOfMotions");
// const LockUp = artifacts.require("LockUp");
// const VotingRules = artifacts.require("VotingRules");

module.exports = async function (callback) {

    const bookeeper = await Bookeeper.deployed();
    console.log("bookeeper address: ", bookeeper.address);

    const bom = await BookOfMotions.deployed();
    console.log("bookOfMotions: ", bom.address);

    const accounts = await web3.eth.getAccounts();
    console.log(accounts);

    // 获取IA
    let ia1 = await Agreement.at("0xC4E573B2156EE33eC577E8176647c74367b0496C");
    console.log("IA address: ", ia1.address);

    // 卖方提交表决
    await bookeeper.proposeMotion(ia1.address, {
        from: accounts[2]
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

    await bom.supportMotion(ia1.address, {
        from: accounts[5]
    });

    console.log("motion is voted");

    // 统计表决结果
    await bom.voteCounting(ia1.address, {
        from: accounts[2]
    });

    console.log("motion is passed");

    // 卖方确认CP成就
    await bookeeper.pushToCoffer("0", ia1.address, "0xa0901f1cd5c43406903d4c99948473e2d7d726ad704aaf6abf6184ea35c70f26", "0", {
        from: accounts[2]
    });

    console.log("share pushed into coffer");

    let strKey = "peace is not free";

    // 买方交割股权
    await bookeeper.closeDeal("0", ia1.address, strKey, {
        from: accounts[8]
    });

    console.log("deal is closed");

    callback();
}