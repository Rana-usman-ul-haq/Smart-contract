// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.7.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.7.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.7.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.7.0/utils/Counters.sol";
import "@openzeppelin/contracts@4.5.0/utils/cryptography/MerkleProof.sol";

contract NFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public mintRate = 0.01 ether;
    uint256 public max_supply = 50;
    bytes32 public root;
    address payable public payments;

    //for merkeltree
    //address = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    //proof = ["0xc21ba819004fa273fb9b334fb970dcc3cf16a4562629c1f49542000b6cd0c655","0xe467c02201f6ccff8dc14d70bf00e8bd2f6d2fc31f703ee3326f1ae45b0569db","0xb49abd4102a5911165e24fb8d9908fce24f2d68b3b60a8b381f5c9b7bda9d7b8","0x8f18f2814d4f4a0e1dce51424e6b609f980996b9934d0ff1844ca9c2e4662a6a"]
    //_root = 0xee09c99c0989bcbc8fe6724e0009475f067dd94a0b35548cede09f53814f0a48
    //in payments at deploy, launch payment contract and enter its address


    constructor(bytes32 _root, address _payments) ERC721("NFT", "NF") payable{
        root = _root;
        payments = payable(_payments);
    }

    /*function baseURI() internal pure override returns (string memory) {
        return "https://api.com"; } enter meta data link*/
    

    function safeMint(address to, bytes32[] memory proof) public payable {
        require(msg.value >= mintRate, "need more eth");
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        require(totalSupply() < max_supply, "cant mint more");
        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
     function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
      function withdraw() public payable onlyOwner {
    (bool success, ) = payable(payments).call{value: address(this).balance}("");
    require(success);
  }
}

