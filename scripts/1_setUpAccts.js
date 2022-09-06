const RC = artifacts.require("RegCenter");

module.exports = async function (callback) {

    // ==== RegCenter Books and Keepers ====

    const rc = await RC.deployed();
    console.log("rc: ", rc.address);

    // ==== accts register ====

    const accounts = await web3.eth.getAccounts();
    console.log("accts: ", accounts);

    const acct0 = await rc.userNo(accounts[0]);
    console.log("acct0: ", acct0.toNumber());

    const acct1 = await rc.userNo(accounts[1]);
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

    callback();
}