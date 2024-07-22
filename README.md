# Important information about the Sui contracts

This repos contains Sui blockchain contracts.

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

+-------------------------+
| Move Coverage Summary   |
+-------------------------+
Module 0000000000000000000000000000000000000000000000000000000000000000::caps
>>> % Module coverage: 100.00
Module 0000000000000000000000000000000000000000000000000000000000000000::moment
>>> % Module coverage: 100.00
Module 0000000000000000000000000000000000000000000000000000000000000000::register
>>> % Module coverage: 100.00
Module 0000000000000000000000000000000000000000000000000000000000000000::token
>>> % Module coverage: 100.00
+-------------------------+
| % Move Coverage: 100.00  |
+-------------------------+
```

Further breakdown of the coverage can be found using the flags, for example:

```sh
collectible % ~/.cargo/bin/sui move coverage summary --summarize-functions > example_full_coverage.json
```

## Contract deployment

The Sui contract is intended to be an analog of the other EVM contracts on
Ethereum, Polygon and Tezos. Each contract represents one CollectibleSeries
object and within that object there can be one or more moments.

```sh
collectible % sui client publish --json > example_publish.json

INCLUDING DEPENDENCY Sui
INCLUDING DEPENDENCY MoveStdlib
BUILDING collectible
Successfully verified dependencies on-chain against source.
```

The json contains important information about the contract, including:
* Overall gas price and breakdowns
* Address of the contract
* ObjectId for the Register, AdminCap, UpgradeCap, etc

### Checking gas price

For example, to see the total gas charge:

```sh
collectible % jq  .balanceChanges\[0\].amount -r example_publish.json
-56315080
```

Or for a gas breakdown:

```sh
collectible % jq .effects.gasUsed example_publish.json
{
  "computationCost": "1000000",
  "storageCost": "56293200",
  "storageRebate": "978120",
  "nonRefundableStorageFee": "9880"
}
```

### Setting the local ENV

To extract the `objectId` and `objectType` for important objects run query on the contract logs:

```sh
collectible % jq '.objectChanges[] | "\(.objectId) \(.objectType) "' -r example_publish.json

0x5cca19d0691183566a3e991016c6a3ed29620e9dbbda99296da953d76784fada 0x2::coin::Coin<0x2::sui::SUI>
0x02c2c913a85d187d1584bdf013936b2cc30a395ea817f0afdda54d70053934b4 0x2::package::UpgradeCap
0x0df8c2deca921313ee5c2fa2bd772024cae6a4e7c15595e23a8ded408e3d718d 0x2::package::Publisher
0x0e67c2fdfc7c9f905d5105b80c0e916088099996c01653d69380e6ecf882dc32 0x2::display::Display<0x79292df28f897303740574ab8c8cc0f3c00d1bd46be5901c878024663c8b2605::token::Token>
0x44e7c11c88e37cd05881b65afe35d8227b4f63f7efc3006606026e90812f1d2f 0x79292df28f897303740574ab8c8cc0f3c00d1bd46be5901c878024663c8b2605::register::Register
0xbbf06b02ff5c00dfbfb0437d60f17429ebb4af37cedbba7afdba7d99c06e4d1a 0x79292df28f897303740574ab8c8cc0f3c00d1bd46be5901c878024663c8b2605::caps::AdminCap
```

These addresses from above can be stored into ENV variable as follows:

```sh
export wallet=$(sui client addresses --json | jq .activeAddress -r)  # senderId
export addr=0x79292df28f897303740574ab8c8cc0f3c00d1bd46be5901c878024663c8b2605  # packageId
export upgrade_cap=0x02c2c913a85d187d1584bdf013936b2cc30a395ea817f0afdda54d70053934b4
export publisher=0x0df8c2deca921313ee5c2fa2bd772024cae6a4e7c15595e23a8ded408e3d718d
export display=0x0e67c2fdfc7c9f905d5105b80c0e916088099996c01653d69380e6ecf882dc32
export register=0x44e7c11c88e37cd05881b65afe35d8227b4f63f7efc3006606026e90812f1d2f
export admin_cap=0xbbf06b02ff5c00dfbfb0437d60f17429ebb4af37cedbba7afdba7d99c06e4d1a
```

### Using the Sui RPC

If the receipt is lost, the objectIds can be pulled from the RPC or the CLI as follows:

```sh
collectible % export last_digest=$(sui client object $addr --json | jq -r .previousTransaction)
collectible % sui client tx-block $last_digest --json > example_receipt.json
collectible % jq .effects.created example_receipt.json
```

Where $addr is the packageId and last_digest is the tx-block that contains the publish instruction.

To get the type information, either use the curl interface and request this directly, or run

```sh
collectible % jq .effects.created example_receipt.json
```

### Using Blockchain Explorers

The same data can be pulled from the blockchain explorer or direct from the RPC. For
convenience, the blockchain explorer method is shown below.

From the packageId lookup the last transaction block, e.g.:
https://suiscan.xyz/testnet/object/0x79292df28f897303740574ab8c8cc0f3c00d1bd46be5901c878024663c8b2605/txs

And from there navigate to the transaction hash itself, e.g.:
https://suiscan.xyz/testnet/tx/Am8FNtoPbduHQXBb8RKw61op4AbJ3AvfqTuoAakFdY5y

The shared and privately owned objects can be found from the data, or scraped from
the RPC and will show the ObjectId and CurrentOwner information.


### Setting the display object

The contract has a default Project URL, Series, Set and Rarity, but
these must be modified at the point the contract is deployed.

To update or set the collection Display template dynamically use:

```sh
collectible % sui client ptb \
   --move-call $addr::token::set_display_template \
       @$display \
       '"My ProjectUrl"' \
       '"My SeriesName"' \
       '"My SetName"' \
       '"My RarityName"' \
   --json > example_set_display.json
```

Alternatively, the defaults used in the contract are constants that can be overridden by the use of WASM template contracts.

For more information on this technique, see:

https://docs.sui.io/guides/developer/nft/asset-tokenization#webassembly-wasm-and-template-package

### Minting one token

To mint a token requires the register shared object. By default the
publisher of the contract is automatically added on the minter
whitelist and so is able to create tokens:

```sh
collectible % sui client ptb \
   --move-call $addr::token::mint \
       '"My TokenName"' \
       '"My TokenDesc"' \
       '"My PreviewImage"' \
       '"https://xxx.com/aaa/1"' \
       '"My TeamName"' \
       '"My PlayerName"' \
       '"My GameDate"' \
       '"My PlayType"' \
       '"My PlayOfGame"' \
       '"My GameDifficulty"' \
       '"My GameClock"' \
       '"My AudioType"' \
       '"My VideoUri"' \
       1 \
       100 \
       @$register \
   --assign token \
   --transfer-objects \[token\] @$wallet \
   --json > example_mint_token.json
```

## Duplicate Token URI

The contract will block duplicate Token Uri, and so repeating this instruction will fail.

Repeating the same mint instruction will generate an abort log, which looks
as follows:

```sh
sweet_token % cat example_mint_token.json

Error executing transaction: Failure {
    error: "MoveAbort(MoveLocation { module: ModuleId { address: 79292df28f897303740574ab8c8cc0f3c00d1bd46be5901c878024663c8b2605, name: Identifier(\"register\") }, function: 4, instruction: 16, function_name: Some(\"register_token_uri\") }, 4) in command 0",
}
```

n.b. On the sui cli, failed transactions caused by code assertions do not produce
clear and obvious failures and so it's important that the logs are inspected after each call.

### Batch minting tokens

There is no cost advantage of attempting to optimize the PTB, and so for convenience
it is recommended that each NFT is supplied every argument on mint.

For example to mint editions #1, #2 and #3 from that moment:

```sh
collectible % sui client ptb \
   --move-call $addr::token::mint '"My Token #1"' '"My TokenDesc"' '"My PreviewImage"' '"https://xxx.com/aaa/2"' \
       '"My TeamName"' '"My PlayerName"' '"My GameDate"' '"My PlayType"' '"My PlayOfGame"' '"My GameDifficulty"' \
       '"My GameClock"' '"My AudioType"' '"My VideoUri"' 1 100 @$register \
   --assign token \
   --transfer-objects \[token\] @$wallet \
   --move-call $addr::token::mint '"My Token #2"' '"My TokenDesc"' '"My PreviewImage"' '"https://xxx.com/aaa/3"' \
       '"My TeamName"' '"My PlayerName"' '"My GameDate"' '"My PlayType"' '"My PlayOfGame"' '"My GameDifficulty"' \
       '"My GameClock"' '"My AudioType"' '"My VideoUri"' 2 100 @$register \
   --assign token \
   --transfer-objects \[token\] @$wallet \
   --move-call $addr::token::mint '"My Token #3"' '"My TokenDesc"' '"My PreviewImage"' '"https://xxx.com/aaa/4"' \
       '"My TeamName"' '"My PlayerName"' '"My GameDate"' '"My PlayType"' '"My PlayOfGame"' '"My GameDifficulty"' \
       '"My GameClock"' '"My AudioType"' '"My VideoUri"' 3 100 @$register \
   --assign token \
   --transfer-objects \[token\] @$wallet \
   --json > example_mint_multiple_tokens.json
```

### Viewing a list of Token URIs

To see the tokens that have been minted so far on this contract:

```sh
collectible % sui client object $register --json | jq .content.fields.token_uris

[
  "https://xxx.com/aaa/1",
  "https://xxx.com/aaa/2",
  "https://xxx.com/aaa/3",
  "https://xxx.com/aaa/4"
]
```


## Advanced operations

This section covers more of the advanced Admin-only operations.

### Adding minters

By default, the wallet that deploys the contract will automatically be
granted minter rights.

To add another minter, use the following:

```sh
collectible % export new_minter_addr=0xBBBB
collectible % sui client ptb \
   --move-call $addr::register::add_minter_whitelist @$register @$new_minter_addr @$admin_cap \
   --json > example_add_new_minter.json
```

If the instruction is repeated with the same minter address then it will abort:

```sh
Error executing transaction: Failure {
    error: "MoveAbort(MoveLocation { module: ModuleId { address: 79292df28f897303740574ab8c8cc0f3c00d1bd46be5901c878024663c8b2605, name: Identifier(\"register\") }, function: 8, instruction: 10, function_name: Some(\"add_minter_whitelist\") }, 5) in command 0",
}
```

### Display minters

To see a list of the minters:

```sh
collectible % sui client object $register --json | jq .content.fields.minter_whitelist

[
  "0xa7fbfa7d189cad54605d194136a04763e73d50f4cda82b91b8292213a3f4534b",
  "0x000000000000000000000000000000000000000000000000000000000000bbbb"
]
```

As can be seen, the new minter (0xBBBB) has been added to the list of approved minters

### Revoking minters

To revoke access for a minter, use the following:

```sh
collectible % sui client ptb \
   --move-call $addr::register::remove_minter_whitelist @$register @$new_minter_addr @$admin_cap \
   --json > example_revoke_minter.json
```

If the command is repeated or an invalid minter is given, then the following error will be seen:

```sh
Error executing transaction: Failure {
    error: "MoveAbort(MoveLocation { module: ModuleId { address: 79292df28f897303740574ab8c8cc0f3c00d1bd46be5901c878024663c8b2605, name: Identifier(\"register\") }, function: 8, instruction: 10, function_name: Some(\"remove_minter_whitelist\") }, 2) in command 0",
}
```

### Freezing the contract

Freezing the contract will block all further mint operations and block any changes to the NFTs.

To freeze the contract, run the following command:

```sh
collectible % sui client ptb \
   --move-call $addr::register::freeze_contract @$register \
   --json > example_freeze_contract.json
```

Burning of the tokens e.g. for gamification, and updates to the display template object
are still permitted when the contract is frozen.

If the command is repeated then it will error, e.g.:

```sh
Error executing transaction: Failure {
    error: "MoveAbort(MoveLocation { module: ModuleId { address: 79292df28f897303740574ab8c8cc0f3c00d1bd46be5901c878024663c8b2605, name: Identifier(\"register\") }, function: 8, instruction: 10, function_name: Some(\"freeze_contract\") }, 3) in command 0",
}
```

### Viewing the Frozen State

To view the frozen state run this command:

```sh
sui client object $register --json | jq .content.fields.is_frozen

true
```

Once the contract is frozen, it will permanently remain in a frozen state.

### Moving the Admin rights

The contract will typically be deployed by the minter wallet and
as a precaution the Admin rights may need to be transferred to
an admin wallet.

To transfer the admin, upgrade, publisher and display caps, run the following commands

```sh
collectible % export admin_addr=0xAAAA
collectible % sui client ptb \
   --transfer-objects \[ @upgrade_cap @publisher @display @admin_cap \] @$admin_addr \
```

Notes:
* Shared objects, such as the register, do not need to be moved.
* Only the owner of the AdminCap will be able to run admin commands
* Display, Publisher and UpgradeCap objects are standard Sui objects


Copyright (C) 2024 SocialSweet Inc.  All rights reserved.
