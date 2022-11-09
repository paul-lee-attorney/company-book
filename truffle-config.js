module.exports = {
    networks: {
        ganache: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "18",
            gasPrice: 20000000000
        },
        loc_development_development: {
            network_id: "*",
            port: 8545,
            host: "127.0.0.1"
        }
    },
    mocha: {},
    compilers: {
        solc: {
            version: "0.8.8",
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200
                }
            }
        }
    }
};