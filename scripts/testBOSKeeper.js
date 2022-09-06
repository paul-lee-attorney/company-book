const BOS = artifacts.require("BookOfShares");
const GK = artifacts.require("GeneralKeeper");

module.exports = async function (callback) {
    const bos = await BOS.deployed();
    console.log("bos: ", bos.address);

    const accounts = await web3.eth.getAccounts();
    console.log("accts: ", accounts);

    const gk = await GK.deployed();
    console.log("gk: ", gk.address);

    // 实缴出资：
    await gk.setPayInAmount(3, 100000000, "0xe4c7c8db728c1f81f24ebcb126c4b32b5a584e7c144d2782bb0ed0e12989f9dc", {
        from: accounts[1]
    });
    console.log("share_3 payInAmount set");

    let locker_3 = await bos.getLocker(3);
    console.log("locker_3 is: (1) amount:", locker_3.amount.toNumber(), " (2) hashLock: ", locker_3.hashLock);

    await gk.requestPaidInCapital(3, "Paul, Frank and Bill.", {
        from: accounts[4]
    });
    console.log("share_3 paidPar granted.");

    let share_3 = await bos.getShare(3);
    console.log("share_3' parValue: ", share_3.parValue.toNumber());
    console.log("share_3' paidPar: ", share_3.paidPar.toNumber());

    await gk.decreaseCapital(2, 100000000, 100000000, {
        from: accounts[1]
    });
    console.log("share_1 decreased 100 MC. ");

    await gk.updateShareState(2, 1, {
        from: accounts[1]
    });
    console.log("share_2 freezed.");

    callback();
}