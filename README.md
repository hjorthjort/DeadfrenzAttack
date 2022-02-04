The Deadfrenz mint pass contract is vulnerable to reentrancy.

If: any holder of a Deadfellaz was a contract at the time when the snapshot for Merkle proofs was taken;
Then: that contract can mint any number of Deadfrenz mint passes they want, up to the max available amount.

Run `dapp test` to check.
Make sure you have your `secrets.sh` file set up to point `MAINNET_RPC_URL` to an archival node (I'll probably spend this proof soon and then the latest block won't work anymore).

If you want to test if you can (or could) perform this exploit, change the `DAPP_TEST_ADDRESS` to your own, and the Merkle proof to your own whitelist proof (can be found by either looking at your claiming transaction, or checking calldata before you send it).
Also make sure `numPasses`, `amount` and `mpIndex` arguments are set to whatever they are in your transaction.