# SolHash

Interwoven Hash implementation in Solidity

---
## Requirements

* [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* [Node.js + npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)

## Installation

```bash
git clone https://github.com/MakoLab/ontochain-foundations
cd ontochain-foundations/SolHash
npm install
# install required tools
sudo npm i -g truffle
sudo npm i -g ganache-cli
```

## Testing

- in a separate console, run [development network](https://ethereum.org/en/developers/docs/development-networks/)
  ```bash
  ganache-cli --account 0xc8c6864cbeb4b1edb66f0a353fae458831da9502219a0c740d94e9842c9210dc,0xfffffffffffffffffff
  ```

- migrate the smart contract and run the test on a sample graph
  ```bash
  truffle migrate
  truffle exec test.js example.n3
  ```
  The result of the test are 2 values - Interwoven Hash calculated for the graph from the file ```example.n3``` using the algorithm implementation in:
  * column 1: JavaScript
  * column 2: Solidity

If you want to run the test on a different network, edit the ```live``` network configuration in the ```truffle-config.js``` file:
```json
new PrivateKeyProvider("<mnemonic/privateKeys>", "<JSON-RPC API Endpoint URL>"),
```
* ```mnemonic/privateKeys```:```string/string[]```.12 word mnemonic which addresses are created from or array of private keys.
* ```providerOrUrl```:```string|object```.URI or Ethereum client to send all other non-transaction-related Web3 requests

and run all commands with the ```--network live``` option:
```bash
truffle --network live migrate
truffle --network live exec test.js example.n3 
```
