const BOS = artifacts.require("BookOfShares");
const GK = artifacts.require("GeneralKeeper");
const BOAKeeper = artifacts.require("BOAKeeper");
const RC = artifacts.require("RegCenter");

module.exports = async function (callback) {
    const bos = await BOS.deployed();
    console.log("bos: ", bos.address);

    const accounts = await web3.eth.getAccounts();
    console.log("accts: ", accounts);

    const boaKeeper = await BOAKeeper.deployed();
    console.log("boaKeeper: ", boaKeeper.address);

    const gk = await GK.deployed();
    console.log("gk: ", gk.address);

    const rc = await RC.deployed();
    console.log("rc: ", rc.address);

    let acct1 = await rc.userNo(accounts[1], {
        from: accounts[1]
    });
    console.log("acct1: ", acct1.toNumber());

    await rc.regUser(1, 0, {
        from: accounts[2]
    });
    console.log("acct2 registered ");

    let acct2 = await rc.userNo(accounts[2], {
        from: accounts[2]
    });
    console.log("acct2: ", acct2.toNumber());

    await rc.regUser(1, 0, {
        from: accounts[3]
    });
    console.log("acct3 registered.");

    const acct3 = await rc.userNo(accounts[3], {
        from: accounts[3]
    });
    console.log("acct3: ", acct3.toNumber());

    await rc.regUser(1, 0, {
        from: accounts[4]
    });
    console.log("acct4 registered.");
    const acct4 = await rc.userNo(accounts[4], {
        from: accounts[4]
    });
    console.log("acct4: ", acct4.toNumber());

    await rc.regUser(1, 0, {
        from: accounts[5]
    });
    console.log("acct5 registered.");
    const acct5 = await rc.userNo(accounts[5], {
        from: accounts[5]
    });
    console.log("acct5: ", acct5.toNumber());

    // 设定股权结构：
    await bos.issueShare(acct2.toNumber(), "0", "500000000", "500000000", "1597714025", "1470614888", "1", {
        from: accounts[1]
    });
    console.log("issue share_1 ");

    const ssn_3 = await web3.utils.hexToBytes("0x000157a7cd68");

    let share_1 = await bos.getShare(ssn_3);
    console.log("share_1: ", share_1);

    await bos.issueShare(acct3.toNumber(), "0", "300000000", "300000000", "1597714025", "1470614888", "1", {
        from: accounts[1]
    });
    console.log("issue share_2");



    await bos.issueShare(acct4.toNumber(), "0", "200000000", "100000000", "1597714025", "1470614888", "1", {
        from: accounts[1]
    });
    console.log("issue share_3 ");

    // // 实缴出资：
    // await gk.setPayInAmount("0x000357a7cd68", "100000000", "0x06387d2d459fcadcdba106f0223c9351214b97d2a975c9e1951fa39894e8a06da", {
    //     from: accounts[1]
    // });
    // console.log("share_3 payInAmount set");

    //  = await bos.getLocker("0x000357a7cd68");



    // let share3 = await bos.getShare("0x000357a7cd68");
    // console.log("share_3: ", share3);

    // // 股权转让：
    // await bos.transferShare("3", "200000000", "200000000", accounts[5], "0", "10000", {
    //     from: accounts[1]
    // });

    // // 获取BOS的股东列表:
    // let membersList = await bos.membersList();
    // console.log(membersList.toString());

    // let sharesList = await bos.sharesList();
    // console.log(sharesList.toString());

    // // await bos.shareExist("1");
    // // await bos.shareExist("3");
    // // await bos.shareExist("4");

    // // 股权转让：
    // await bos.transferShare("4", "100000000", "100000000", accounts[4], "0", "10000", {
    //     from: accounts[1]
    // });

    // // 获取BOS的股东列表:
    // membersList = await bos.membersList();
    // console.log(membersList.toString());

    // sharesList = await bos.sharesList();
    // console.log(sharesList.toString());

    // // 设定BOS的Bookkeeper
    // await bos.setBookeeper(bookeeper.address, {
    //     from: accounts[1]
    // });

    // let keeperOfBOS = await bos.getBookeeper();

    // console.log(keeperOfBOS);

    callback();
}