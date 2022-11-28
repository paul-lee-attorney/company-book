const Web3 = require("web3");
const provider = new Web3.providers.HttpProvider("http://localhost:8545");
const web3 = new Web3(provider);


module.exports = async function (callback) {

    // web3.setProvider();

    let bn = await web3.eth.getBlockNumber();
    console.log("start BN: ", bn);

    let cur = await web3.eth.getBlock("latest");
    console.log("start timestamp: ", cur.timestamp);

    // for (let i = 0; i < 24; i++) {
    web3.currentProvider.send({
        method: "evm_mine",
        params: [{
            blocks: 10
        }]
    }, () => console.log("t"));
    // }

    bn = await web3.eth.getBlockNumber();
    console.log("end BN: ", bn);

    cur = await web3.eth.getBlock("latest");
    console.log("end timestamp: ", cur.timestamp);

    callback();
}