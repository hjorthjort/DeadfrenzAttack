Keep calm and no one will get rekt
==================================

Frenz, fellaz, countrymen,

I'm hjort.eth.
I am my fella and my fella is me.
(At least on Twitter).
I'm also an auditor.
That's my day job.

Usually, that means I get paid (handsomely) to look at code and find potential exploits.
It's a great experience, securing protocols, helping devs and getting thanked when I find something serious.
This time was different.
For one thing, I had to sit on the secret.
I tried sharing the exploit with the devs, but got no responese.
Unfortunately, that meant all I could do was sit on my hands, not make noise and just keep my fingers crossed.
It was an unusal decision, and I'll explain my motivation towards the end.
I hope you agree I did the right thing.

**But I also think we should be doing better.**
I'm not happy with the answers I got to this explout report, and frankly, I think neither should you be.

**Note**: Since there has been no public disclosure of the bug, I can't know if the team ever addressed it.
They did disclose an issue early on for which they paused the contract, but that is a different issue from the ones I bring up here.

![](screenshots/announcement_discord.png)

I do know that the reentrancy issue (the most severe one) was never exploited, but I can't say if that's luck or if the team did the mitigation I suggested.

## Checking the code, finding the bugs

I was as happy as anyone to hear about the Deadfrenz launch.
And since I know a thing or two about Solidity, I wanted to check out the contract before I claimed my pass.
I'll admit the reasons for this were not entirerly honorable.
You see, it's a tricky problem in NFTs to make sure that launches are fair and that randomness works, so it's often a good idea to inspect some contract source when there's a new launch. 
Maybe I could try and time my transaction and get a higher rarity score or something, IDK?
Never hurts to check.

What I did find were two security holes.
One was less severe, and meant that, had people realized it, the pass sale would have lost some revenue.
One was extremely severe, but I didn't know if it was exploitable.

## The kinda bad

In short, anyone who was allowed to mint a few different paid passes (0.1 ETH or 0.15 ETH each) would not have to pay full price.
At most, someone could mint their passes for 1/3rd of the price.
This would be bad.
But even if some users knew, they would each be able to cheat the protocol/team out of at most a few ETH.
There would be no real loss to users, and the attack does not really scale well.
I made a proof of concept attack and concluded it was possible, and I told the team.
But if that was all, I wouldn't be writing this post now.

The second attack put user funds (passes) at serious risk, and was infinitely scalable.
If it had been attacked, all your passes could have become worthless and we would need to roll back the whole mint and redo.
Some of you could have bought worthless passes on OpenSea or LooksRare, for real ETH, and be stuck rekt.

## The very bad

Here's how it works:

```solidity
    function claim(
        uint256 numPasses,
        uint256 amount,
        uint256 mpIndex,
        bytes32[] calldata merkleProof
    ) external payable {
        // verify call is valid
        
        require(isValidClaim(numPasses,amount,mpIndex,merkleProof));
        
        //return any excess funds to sender if overpaid
        uint256 excessPayment = msg.value.sub(numPasses.mul(mintPasses[mpIndex].mintPrice));
        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }
        
        mintPasses[mpIndex].claimedMPs[msg.sender] = mintPasses[mpIndex].claimedMPs[msg.sender].add(numPasses);
        
        _mint(msg.sender, mpIndex, numPasses, "");

        emit Claimed(mpIndex, msg.sender, numPasses);
    }
```

The issue is the `if`-branch.
It makes some sense that you would want to send any extra ETH back (though just checking that the amount sent is exactly right is usually better).
But what makes this very dangerous is the send happens before any update to the mint contract.
That's why we always say "checks, effects, interactions".
Don't interact with an external address until you have updated your local variables.
Specifically, the number of minted passes has not been updated yet.

This is a typical reentrancy bug.
An attacker can easily set up a contract with a fallback function and send 1 wei more than necessary when calling `claim`.
That will cause this function to call back to the sender, triggering the fallback function, which can then call the `claim` again, and succeed because the contract has not yet registered the previous claim.

This way, the attacker can mint as many passes as they like, they can even mint more than the max total ceiling on the tokens, because at every call the contract thinks it's performing the first mint.

That would be bad.

Normally, as a whitehat, if I found this and didn't get an immediate response from the team I would just perform the attack myself, drain all the tokens, and then coordinate with the team about how to redistribute.
That's better than having such an exploit sit out in the open, waiting for a blackhat hacker to steal all the tokens and sell them for market price on OpenSea, making of with a bunch of ETH.

But I couldn't, and that is what makes this exploit so different, and also why I didn't disclose it why the mint was ongoing.

## Why didn't I exploit this?

First of all -- I would have if I could, but as a whitehat.
I would have minted all the tokens in the pool I could exploit, then chat with the devs and figure out how to make sure they get properly distributed.
100% doable, not even very expensive (except for me, I have to pay a lot of gas).

But I couldn't.
Because this is a reentrancy attack, only a contract can execute it.
I was holding my Deadfella in a regular externally owned address (EOA).
Because they are using a Merkle proof where the `msg.sender` is included in the node, there's no way I or anyone else can make the call from any address not included in the snapshot.
That also means that even if you held your eligible NFT in a contract at the time of the snapshot, you might not be able to perform the reentrancy attack.

## So what's the problem?

The problem is that someone could probably exploit this.
There are contracts which are upgradable, or support executing any code, including the necessary code to do the attack.
In fact, it's a common feature of contract wallets, such as Gnosis Safe.
The main question I was worried about when I reached out to the team was: are there any contract addresses included in the snapshot, and which are they?

I later found at least one verified DF holder in the Discord asking if it would be possible to claim from his Gnosis Safe.

![It's almost a bit sad that they don't know they could have minted any number of passes they wanted. A would-be hacker missed their payday here.](screenshots/gnosis_discord.png)

If I, or the dev team, could just scan through the eligible addresses and make sure there are none in there which could perform the attack, we could exclude them from the claim by upgrading the Merkle root.
Some Merkle roots were upgraded several times during the claim period.
It is entirely possible that the team had realized the problem and patched it themselves.

## What damage could have been done?

An attacker for the reentrancy could mint an arbitrary amount of mint passes.
Perhaps the most clever thing would have been to mint and immediately do a quick dump on OpenSea, making off with a few ETH (when I checked, there were 6 open bids at ~0.65 ETH per pass that could be executed directly).
They could also just hold on to some passes and sell them later.
As long as the amount was not too great, and they managed to go undetected (or ignored) by the team, they could simply be owning or dumping a bunch of extra Deadfrenz.

The reentrancy bug was never exploited.
I have checked the [contract log of internal transactions](https://etherscan.io/txsInternal?a=0x090f688f0c11a8671c47d833af3cf965c30d3c35&&m=advanced&p=200), and the earliest one is from after minting closed.
Phew, I guess.

## Feedback time

So here's what the team did well:

- They did a secret snapshot + Merkle proof drop.
  That reduces attack surfaces in many cases.
- For all I know, they may have updated the eligible minters to make sure no contracts were included
  By the nature of how authentication works, there's no way for me to know.

What do I wish could have been done differently:

- If you find an issue and patch it, you should disclose it.
  It's the responsible thing to do.
  It lets people know that you are on top of the issue.
  For now, I have to assume they were not aware, and chose to ignore it when it was reported.
- I you get a whitehat report (like the ones I sent), acknowledge it and connect the whitehat to a dev.
  If you are 100% sure that your devs are aware of the issue, then you should tell the whitehat that, and point to the mitigation (a transaction usually).
  If you are less than 100% sure, just connect us.
  We can chat for 10 minutes and possibly figure out whether all bases have been covered.
  If they haven't, we can talk mitigations.
- Say "thanks for not hacking us".
  This may sound petty, but I get pretty annoyed when I spend some free time securing your token, and don't try to exploit it (by finding a partner, in this case), and I get stonewalled.
  There are blackhat hackers as well, and in this case their efforts would probably be worth their while, so make sure to thank your whitehats.

## Why did I wait to disclose publicy?

When the team failed to get back to me within a day and I had received a message saying everything was fine(!), I had to decide how to proceed.
The attack required both opportunity and knowledge, and given that an attacker could hardly have anticipated the opportunity (the snapshot + the bug) it seemed likely that no one had both.
I was in a Dark Forest-like situation.
The fact that the bug was obscure seemed to be its greates strength.
Even if I just disclosed that there is some bug, that would be enough for any reasonably sophisticated user to go and check out the contract and likely immediately locate the issue.
I still feel iffy about that decision.

I considered finding a partner in crime with whom I could whitehat.
But that would require some special trust: there would be no guarantee that the person on the other end would not just floor dump their tokens once they got them.
It seemed less responsible to even attempt.
And again, just going around looking for someone with a DF in a contract account could raise suspicion.

It turned out well in the end, but I would have liked a safer approach.

Once the mint of the passes was over, there was no rush anymore either, so I figured I should wait until after the Deadfrenz mint + reveal buzz was over.
I want to spark some discussion about security practices in the project and what can be done better in the future, and didn't want that to get drowned out, and I didn't want to cause a panic in the middle of a frenzy.
I also wanted to check the Deadfrenz contract for any bugs before attracting more attention to it.
I did, it looks clean.
Good job devs!

# TODO: Some more screenshots of convos

## Formal details

The exploits outlined in this repo were reported to the Deadfellaz team on
- Feb 4, 2022, 15:25 UTC (reentrancy)
- Feb 5, 2022, 15:46 UTC (cheap mint)

These exploits were reported to the Deadfellaz team via:
- Twitter: @betty_nft
- Twitter: @psych_nft
- Twitter: @Deadfellaz
- Discord: contact with unnamed mod.

They were reported with a high-level description and proof-of-concept.

