const PrivateKeyProvider	= require("@truffle/hdwallet-provider");

module.exports = {
  networks: {
    development: {
      host:			"127.0.0.1",
      port:			8545,
      network_id:		"*"
    },
    live: {
      provider:			new PrivateKeyProvider("c8c6864cbeb4b1edb66f0a353fae458831da9502219a0c740d94e9842c9210dc", "http://127.0.0.1:8545"),
      network_id:		"*",
      networkCheckTimeout:	1000000,
      timeoutBlocks:		200
    }
  },
  compilers: {
    solc: {
      version: "0.8.0"
    }
  },
};
