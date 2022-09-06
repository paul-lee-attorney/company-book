const Web3 = require("web3");
const provider = new Web3.providers.HttpProvider("http://localhost:8545");
const web3 = new Web3(provider);


module.exports = async function (callback) {

    // web3.setProvider();

    let bn = await web3.eth.getBlockNumber();
    console.log("current BN: ", bn);

    let cur = await web3.eth.getBlock("latest");
    console.log("current timestamp: ", cur.timestamp);

    for (let i = 0; i < 24; i++) {
        await web3.currentProvider.send({
            method: "evm_mine"
        }, () => console.log(i));
    }

    bn = await web3.eth.getBlockNumber();
    console.log("current BN: ", bn);

    cur = await web3.eth.getBlock("latest");
    console.log("current timestamp: ", cur.timestamp);

    callback();
}