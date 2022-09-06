const BOS = artifacts.require("BookOfShares");
const GK = artifacts.require("GeneralKeeper");
// const setUpBOS = require("../scripts/setUpBOS");

contract("BOSKeeper", (accounts) => {
    let event = null;
    let gk = null;
    let bos = null;

    beforeEach(async () => {
        // setUpBOS();
        gk = await GK.deployed();
        bos = await BOS.deployed();
    })

    it("should set payIn amount", async () => {
        await gk.setPayInAmount(3, 100000000, "0xe4c7c8db728c1f81f24ebcb126c4b32b5a584e7c144d2782bb0ed0e12989f9dc", {
            from: accounts[1]
        });
        event = await bos.getPastEvents("SetPayInAmount");
        assert.equal(event[0].args.ssn.toNumber(), 3, "ssn not correct");
        // assert.equal(event[0].args.amount.toNumber(), 100000000, "amount not correct");
        // assert.equal(event[0].args.hashLock, 100000000, "0xe4c7c8db728c1f81f24ebcb126c4b32b5a584e7c144d2782bb0ed0e12989f9dc");
    });
})