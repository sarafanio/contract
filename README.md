# Sarafan contracts

This repository contains sources for Sarafan network contracts.

Contracts follow the rules described in [the whitepaper](https://github.com/sarafanio/docs/blob/master/whitepaper.md).

Contracts deployed to Ethereum **MAINNET**:

* SRFN token contract: `0x957D0b2E4afA74A49bbEa4d7333D13c0b11af60F` (**send ether here to receive SRFN tokens**)
* Content contract: `0x216c867a6bB7eFE026fA67eCB66ba65E1126598E`
* Peering contract: `0x11ECFE316b0782f8785287511Ea70a3FF51e0Dec`

Contracts was deployed to **ROPSTEN**:

* SRFN token contract: `0x4B5eBE5dd2b2F3eEa801161FF94693fb682ABAb7`
* Content contract: `0xfa7b2804039570a5DCd355A6A572c291Cf8A31b0`
* Peering contract: `0x6D6ad4A22Af50BD718171C65cd7a8E9DCaedc14E`


## Development

You can use contract source in development of client app (for example.).

You need to install truffle and ganash first.

Ganash is an app that help you to create your local blockchain for development
and can be downloaded at https://www.trufflesuite.com/ganache

Truffle can be installed using npm:

```
npm install -g truffle
```

Then you need to run ganache with new network and deploy contracts with truffle:

```
truffle deploy
```

Contracts addresses will be printed out to console.

You can also run provided tests:

```
truffle test
```

## Secrets

There are two secrets files:

* `.secret` containing private key for public network deployment
* `.infura` containing infura project id to access public networks
