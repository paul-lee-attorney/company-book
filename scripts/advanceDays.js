const rpcPromise = (rpcData, web3) => {
    return new Promise((resolve, reject) => {
        const data = {
            id: new Date().getTime(),
            jsonrpc: "2.0"
        };
        web3.currentProvider.send({
            ...data,
            ...rpcData
        }, (err, result) => {
            if (err) reject(err);
            return resolve(result.result);
        });
    });
};

const mineBlock = (numOfDays, web3) => rpcPromise({
    method: "evm_mine",
    params: [{
        blocks: 240 * numOfDays
    }]
}, web3);

const advanceDays = async (numOfDays, web3) => {
    if (!numOfDays) return;
    let curTime = await getCurrentTime(web3);
    curTime = curTime * 1000 + numOfDays * 86400000;

    const setDaysResult = await rpcPromise({
        method: "evm_setTime",
        params: [curTime],
    }, web3);

    return mineBlock(numOfDays, web3);
};

const getCurrentTime = async (web3) => {
    const block = await rpcPromise({
        method: "eth_getBlockByNumber",
        params: ["latest", false],
    }, web3);

    const ts = block.timestamp;
    const timestamp = parseInt(ts);
    return timestamp;
};

const getCurrentBN = async (web3) => {
    const block = await rpcPromise({
        method: "eth_getBlockByNumber",
        params: ["latest", false],
    }, web3);

    const bn = block.number;
    const blocknumber = parseInt(bn);
    return blocknumber;
};

module.exports = {
    getCurrentTime,
    getCurrentBN,
    advanceDays
};