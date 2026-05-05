// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @notice ERC-721 mint gated by a Merkle root; allowlist is off-chain (no allowlist mapping).
contract MerkleWhitelistNFT is ERC721 {
    bytes32 public immutable merkleRoot;
    uint256 public immutable maxSupply;

    uint256 private _tokenIdCounter;
    mapping(address account => bool) private _hasMinted;

    error AlreadyMinted();
    error InvalidProof();
    error SoldOut();

    constructor(string memory name_, string memory symbol_, bytes32 merkleRoot_, uint256 maxSupply_)
        ERC721(name_, symbol_)
    {
        merkleRoot = merkleRoot_;
        maxSupply = maxSupply_;
    }

    function hasMinted(address account) external view returns (bool) {
        return _hasMinted[account];
    }

    function mint(bytes32[] calldata proof) external {
        if (_hasMinted[msg.sender]) revert AlreadyMinted();
        if (_tokenIdCounter >= maxSupply) revert SoldOut();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert InvalidProof();

        _hasMinted[msg.sender] = true;
        unchecked {
            ++_tokenIdCounter;
        }
        _safeMint(msg.sender, _tokenIdCounter);
    }

    function totalMinted() external view returns (uint256) {
        return _tokenIdCounter;
    }
}
