# Merkle whitelist NFT (ERC-721)

Foundry project demonstrating an **ERC-721** mint where the allowlist lives **off-chain** as a Merkle tree. On-chain there is only an immutable `merkleRoot`; **no mapping stores the allowlist**. A `mapping(address => bool) hasMinted` is used only to enforce **one mint per address** (replay protection), not to store who is allowed.

- **Leaf**: `keccak256(abi.encodePacked(account))` for each allowlisted `account`.
- **Proof**: OpenZeppelin `MerkleProof.verify` ([`MerkleProof.sol`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)); internal nodes use sorted commutative hashing (`keccak256(abi.encode(a, b))` style), matching [`@openzeppelin/merkle-tree`](https://github.com/OpenZeppelin/merkle-tree) if you generate roots off-chain.

## Build and test

```shell
forge build
forge test
forge fmt
```

## Contract

[`src/MerkleWhitelistNFT.sol`](src/MerkleWhitelistNFT.sol) — constructor takes `name`, `symbol`, `merkleRoot`, and `maxSupply`. Call `mint(bytes32[] calldata proof)` with a proof for `msg.sender`.

## Generating a root off-chain

Use any tool that builds the same tree as OpenZeppelin’s JS library, or mirror the test in [`test/MerkleWhitelistNFT.t.sol`](test/MerkleWhitelistNFT.t.sol): leaves are `keccak256(abi.encodePacked(address))`, parents are `Hashes.commutativeKeccak256` / OZ `standardNodeHash`.

**Beginner caveat:** A single `keccak256(abi.encodePacked(leaf))` leaf is simple to teach; for production, consider OZ’s double-hash leaf convention to avoid ambiguous 64-byte leaf edge cases (see MerkleProof.sol comments).

## Cast (example)

After deployment, minters call `mint` with their proof array; encode calldata with `cast calldata "mint(bytes32[])" …` or your frontend.

## License

MIT
