const BookOfShares = artifacts.require("BookOfShares");
const Bookeeper = artifacts.require("Bookeeper");

module.exports = async function (callback) {
    const bos = await BookOfShares.deployed();
    const accounts = await web3.eth.getAccounts();
    const bookeeper = await Bookeeper.deployed();

    // 设定BOS的Bookkeeper为外部账户
    await bookeeper.setKeeperOfBook(bos.address, accounts[1], {
        from: accounts[1]
    });

    // 设定股权结构：
    await bos.issueShare(accounts[2], "0", "500000000", "500000000", "1533686888", "1470614888", "10000", {
        from: accounts[1]
    });
    await bos.issueShare(accounts[3], "0", "300000000", "300000000", "1533686888", "1470614888", "10000", {
        from: accounts[1]
    });
    await bos.issueShare(accounts[4], "0", "200000000", "100000000", "1533686888", "1470614888", "10000", {
        from: accounts[1]
    });

    // 实缴出资：
    await bos.payInCapital("3", "100000000", "0", {
        from: accounts[1]
    });
    await bos.getShare("3");

    // 股权转让：
    await bos.transferShare("3", "200000000", "200000000", accounts[5], "0", "10000", {
        from: accounts[1]
    });

    // 获取BOS的股东列表:
    let membersList = await bos.membersList();
    console.log(membersList.toString());

    let sharesList = await bos.sharesList();
    console.log(sharesList.toString());

    // await bos.shareExist("1");
    // await bos.shareExist("3");
    // await bos.shareExist("4");

    // 股权转让：
    await bos.transferShare("4", "100000000", "100000000", accounts[4], "0", "10000", {
        from: accounts[1]
    });

    // 获取BOS的股东列表:
    membersList = await bos.membersList();
    console.log(membersList.toString());

    sharesList = await bos.sharesList();
    console.log(sharesList.toString());

    // 设定BOS的Bookkeeper
    await bos.setBookeeper(bookeeper.address, {
        from: accounts[1]
    });

    let keeperOfBOS = await bos.getBookeeper();

    console.log(keeperOfBOS);

    callback();
}