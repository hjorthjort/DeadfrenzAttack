# Report

[[REPORT.md]

# Reentrancy

The Deadfrenz mint pass contract is vulnerable to reentrancy.

If: any holder of a Deadfellaz was a contract at the time when the snapshot for Merkle proofs was taken;
Then: that contract can mint any number of Deadfrenz mint passes they want, up to the max available amount.

*This was likely true of at least one user, so the attack was viable.*
It was also completely *avoidable*. This was not a technical trade-off.
Swapping two lines (and thus conforming to the checks-effects-interactions pattern that developers should all be familiar with) would have solved this.

Run `dapp test` to check.
Make sure you have your `secrets.sh` file set up to point `MAINNET_RPC_URL` to an archival node (I'll probably spend this proof soon and then the latest block won't work anymore).

If you want to test if you can (or could) perform this exploit, change the `DAPP_TEST_ADDRESS` to your own, and the Merkle proof to your own whitelist proof (can be found by either looking at your claiming transaction, or checking calldata before you send it).
Also make sure `numPasses`, `amount` and `mpIndex` arguments are set to whatever they are in your transaction.

# Cheap Mint

Anyone eligible to mint passes from more than one pool could have gotten away with paying for only the most expensive pool mint.
For example, if a user was allowed to mint 4 passes of batch 3, 3 passes of batch 5, and 2 passes of batch 5, their total should have been `4 * 0.1 + 3 * 0.1 + 2 * 0.15 ETH = 1 ETH`.
Instead they could have gotten away with paying only `0.4 * 0.1 ETH = 0.4 ETH`.

The example exploit uses one transaction (which took place) in which the user paid 0.25 ETH when they could have gotten away with 0.15 ETH.
