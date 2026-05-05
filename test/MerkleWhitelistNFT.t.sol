// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MerkleWhitelistNFT} from "../src/MerkleWhitelistNFT.sol";
import {Hashes} from "@openzeppelin/contracts/utils/cryptography/Hashes.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleWhitelistNFTTest is Test {
    MerkleWhitelistNFT internal nft;

    address internal alice;
    address internal bob;
    address internal carol;
    address internal dave;

    bytes32[4] internal leaves;
    bytes32 internal root;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");
        dave = makeAddr("dave");

        leaves[0] = keccak256(abi.encodePacked(alice));
        leaves[1] = keccak256(abi.encodePacked(bob));
        leaves[2] = keccak256(abi.encodePacked(carol));
        leaves[3] = keccak256(abi.encodePacked(dave));

        bytes32[] memory tmp = new bytes32[](4);
        for (uint256 i = 0; i < 4; i++) {
            tmp[i] = leaves[i];
        }
        root = _buildRoot(tmp);

        nft = new MerkleWhitelistNFT("Merkle WL", "MWL", root, 100);
    }

    function testMintWithValidProof() public {
        vm.prank(alice);
        nft.mint(_proofForIndex(0));

        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.ownerOf(1), alice);
        assertTrue(nft.hasMinted(alice));
    }

    function testLeafMatchesOpenZeppelinMerkleProof() public view {
        bytes32 leaf = keccak256(abi.encodePacked(alice));
        assertTrue(MerkleProof.verify(_proofForIndex(0), root, leaf));
    }

    function testSecondMintReverts() public {
        vm.startPrank(alice);
        nft.mint(_proofForIndex(0));
        vm.expectRevert(MerkleWhitelistNFT.AlreadyMinted.selector);
        nft.mint(_proofForIndex(0));
        vm.stopPrank();
    }

    function testInvalidProofReverts() public {
        bytes32[] memory badProof = new bytes32[](1);
        badProof[0] = bytes32(uint256(1));

        vm.prank(alice);
        vm.expectRevert(MerkleWhitelistNFT.InvalidProof.selector);
        nft.mint(badProof);
    }

    function testWrongLeafReverts() public {
        address eve = makeAddr("eve");

        vm.prank(eve);
        vm.expectRevert(MerkleWhitelistNFT.InvalidProof.selector);
        nft.mint(_proofForIndex(0));
    }

    function testMultipleAllowlistedMinters() public {
        vm.prank(alice);
        nft.mint(_proofForIndex(0));
        vm.prank(bob);
        nft.mint(_proofForIndex(1));

        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(2), bob);
        assertEq(nft.totalMinted(), 2);
    }

    function _proofForIndex(uint256 leafIndex) internal view returns (bytes32[] memory proof) {
        require(leafIndex < 4, "index");
        bytes32[] memory buf = new bytes32[](4);
        for (uint256 i = 0; i < 4; i++) {
            buf[i] = leaves[i];
        }
        uint256 bufLen = 4;
        uint256 idx = leafIndex;
        proof = new bytes32[](2);
        uint256 step;

        while (bufLen > 1) {
            uint256 sibling = idx ^ 1;
            proof[step++] = buf[sibling];

            for (uint256 j = 0; j < bufLen; j += 2) {
                buf[j / 2] = Hashes.commutativeKeccak256(buf[j], buf[j + 1]);
            }
            bufLen /= 2;
            idx /= 2;
        }
    }

    function _buildRoot(bytes32[] memory layer) internal pure returns (bytes32) {
        uint256 len = layer.length;
        while (len > 1) {
            uint256 next = 0;
            for (uint256 i = 0; i + 1 < len; i += 2) {
                layer[next++] = Hashes.commutativeKeccak256(layer[i], layer[i + 1]);
            }
            len = next;
        }
        return layer[0];
    }
}
