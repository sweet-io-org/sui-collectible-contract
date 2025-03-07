# Important information about the Sui contracts

Sui smart contracts to support Sweet Collectible Packs. There are three main types of Objects: Packs, Moment, and PackTokenPool:

* Moment: represents a memorable sporting event, typically involving a video and metadata about the event.
* Pack: used to claim a random collection of Moments.  For example, a Pack might allow a user to claim 6 random Moments, and the user will not know the exact moments until they open the pack.
* PackTokenPool: a shared object that contains all of the potential Momemnts that might be delivered to a Pack. Moment selection is made through [On Chain Randomness](https://docs.sui.io/guides/developer/advanced/randomness-onchain).


## Dev notes

To get started, install the SUI CLI:

```sh
sui-contracts % brew install sui
```

Alternatively, the RPC API can be invoked directly from curl.

### Client Configuration

Keys for test accounts can be imported using the `sui` CLI:

```shell
sui keytool import "<Mnemonic>" ed25519 "m/44'/784'/0'/0'/0'"
```

And can be set active using the key's phrase:

```shell
sui client switch --address <address-phrase>
```

The testnet should also be set via the CLI:

```shell
sui client new-env --alias testnet --rpc http://testnet.sui.sweet.io:9000
sui client switch --env testnet
```

To obtain gas tokens:

```sh
sui-contracts % sui client faucet
```

To check your balance:

```sh
sui-contracts % sui client gas
```

## Testing Contract

By default, the unit-tests run in parallel which makes the debug
logs harder to analyze. To force single-threaded operation run the
unit-tests as follows:

```sh
collectible % sui move test --threads 1 > test_results.log
```

The result of the test along with any debug messages can be viewed as follows:

```sh
collectible % tail -1 test_results.log

Test result: OK. Total tests: 37; passed: 37; failed: 0
```

### Test coverage

To see test coverage requires a debug version of the SUI client, which can
be compiled from the latest Rust source code. When this is done, unittest
coverage can be accessed as follows:

```sh
collectible % ~/.cargo/bin/sui move test --coverage
collectible % ~/.cargo/bin/sui move coverage summary
```


Copyright (C) 2024 SocialSweet Inc.  All rights reserved.
