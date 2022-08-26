const BOS = artifacts.require("BookOfShares");
const GK = artifacts.require("GeneralKeeper");
const BOAKeeper = artifacts.require("BOAKeeper");
const RC = artifacts.require("RegCenter");

module.exports = async function (callback) {
    const bos = await BOS.deployed();
    console.log("bos: ", bos.address);

    const accounts = await web3.eth.getAccounts();
    console.log("accts: ", accounts);

    // const boaKeeper = await BOAKeeper.deployed();
    // console.log("boaKeeper: ", boaKeeper.address);

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

    const acct2 = await rc.userNo(accounts[2], {
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

    await rc.regUser(1, 0, {
        from: accounts[6]
    });
    console.log("acct6 registered.");

    const acct6 = await rc.userNo(accounts[6], {
        from: accounts[6]
    });
    console.log("acct6: ", acct6.toNumber());

    await rc.regUser(1, 0, {
        from: accounts[7]
    });
    console.log("acct7 registered.");

    const acct7 = await rc.userNo(accounts[7], {
        from: accounts[7]
    });
    console.log("acct7: ", acct7.toNumber());

    await rc.regUser(1, 0, {
        from: accounts[8]
    });
    console.log("acct8 registered.");

    const acct8 = await rc.userNo(accounts[8], {
        from: accounts[8]
    });
    console.log("acct8: ", acct8.toNumber());

    await rc.regUser(1, 0, {
        from: accounts[9]
    });
    console.log("acct9 registered.");

    const acct9 = await rc.userNo(accounts[9], {
        from: accounts[9]
    });
    console.log("acct9: ", acct9.toNumber());

    // 设定股权结构：
    await bos.issueShare(acct2.toNumber(), 0, 500000000, 500000000, 1597714025, 1470614888, 1);
    const share_1 = await bos.getShare("1");
    console.log("issued share_1: ", share_1.shareNumber);

    await bos.issueShare(acct3.toNumber(), 0, 300000000, 300000000, 1597714025, 1470614888, 1);
    const share_2 = await bos.getShare("2");
    console.log("issued share_2: ", share_2.shareNumber);

    await bos.issueShare(acct4.toNumber(), 0, 200000000, 100000000, 1597714025, 1470614888, 1);
    const share_3 = await bos.getShare("3");
    console.log("issued share_3: ", share_3.shareNumber);

    const boaKeeper = await BOAKeeper.deployed();
    await bos.setManager(1, accounts[0], boaKeeper.address);

    // // 获取BOS的股东列表:
    // let members = await bos.members();
    // console.log(members.toString());

    // let sharesList = await bos.snList();
    // console.log(sharesList.toString());


    // // 实缴出资：
    // await gk.setPayInAmount(3, 100000000, "0xe4c7c8db728c1f81f24ebcb126c4b32b5a584e7c144d2782bb0ed0e12989f9dc", {
    //     from: accounts[1]
    // });
    // console.log("share_3 payInAmount set");

    // let locker_3 = await bos.getLocker(3);
    // console.log("locker_3 is: (1) amount:", locker_3.amount.toNumber(), " (2) hashLock: ", locker_3.hashLock);

    // await gk.requestPaidInCapital(3, "Paul, Frank and Bill.", {
    //     from: accounts[4]
    // });
    // console.log("requested share_3 paidPar");
    // console.log("share_3' paidPar: ", share_3.paidPar.toNumber());


    // let share3 = await bos.getShare("0x000357a7cd68");
    // console.log("share_3: ", share3);

    // // 股权转让：
    // await bos.transferShare("3", "200000000", "200000000", accounts[5], "0", "10000", {
    //     from: accounts[1]
    // });


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