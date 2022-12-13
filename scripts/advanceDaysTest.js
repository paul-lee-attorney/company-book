const {
    getCurrentTime,
    getCurrentBN,
    advanceDays
} = require("./advanceDays");


module.exports = async function (callback) {

    console.log("start: ", await getCurrentBN(web3), await getCurrentTime(web3));
    await advanceDays(10, web3);
    console.log("end: ", await getCurrentBN(web3), await getCurrentTime(web3));

    callback();
}