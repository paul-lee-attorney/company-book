const BOS = artifacts.require("BookOfShares");
const IA = artifacts.require("InvestmentAgreement");
const RC = artifcats.require("RegCenter");


contract("InvestmentAgreement", (accounts) => {
    beforeEach(async () => {
        let rc = await RC.deployed();
        let bos = await BOS.deployed();

        await rc.regUser(1, 0, {
            from: accounts[1]
        });

        await rc.regUser(1, 0, {
            from: accounts[2]
        });

        let acct0 = await rc.userNo(accounts[0]);
        let acct1 = await rc.userNo(accounts[1]);
        let acct2 = await rc.userNo(accounts[2]);

        bos.init(accounts[0], accounts[1], rc.address, 2, 0);
        let companyNo = await rc.userNo(bos.address);

        await bos.issueShare(acct2.toNumber(), 0, 500000000, 500000000, 1666175347, 1470614888, 1);
        const share_1 = await bos.getShare("1");
        console.log("issued share_1: ", share_1.shareNumber);

        await bos.issueShare(acct3.toNumber(), 0, 300000000, 300000000, 1666175347, 1470614888, 1);
        const share_2 = await bos.getShare("2");
        console.log("issued share_2: ", share_2.shareNumber);

        await bos.issueShare(acct4.toNumber(), 0, 200000000, 100000000, 1666175347, 1470614888, 1);
        const share_3 = await bos.getShare("3");
        console.log("issued share_3: ", share_3.shareNumber);

        let ia = await IA.deployed();
        ia.init(accounts[0], accounts[1], rc.address, 23, companyNo.toNumber());

        ia.setManager(2);

    });

    it("should ");
});