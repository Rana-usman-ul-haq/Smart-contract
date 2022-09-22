// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CelebrityNFT is ERC721, ERC721Enumerable, Ownable {

     struct BuyNFTStruct {
        string id;
        uint256 price;
        address tokenAddress;
        address refAddress;
        string nonce;
        string uri;
     }

      event BuyEvent(
        address indexed user,
        string id,
        uint256 tokenId,
        string nonce,
        address tokenAddress,
        uint256 price,
        uint64 timestamp
     ); 

    address public fundAddress;
    uint256 public commissionRate;
    string private baseURI;

    uint public constant mintPrice = 0;
    uint256 total_value;

    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("Celebrity.sg", "Celebrity.sg"){
        commissionRate=10;
        fundAddress= msg.sender;
    }

     function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable){
        super._beforeTokenTransfer(from,to,tokenId);
    }

     function tokenURI(uint256 tokenId)
      public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    } 

   function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual 
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    } 
   
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function buyNFT(BuyNFTStruct calldata data) public payable {

        uint256 refAmount;
        uint256 price = data.price;

        if (data.refAddress != address(0)) {
            refAmount = (data.price * commissionRate) / 100;
            price = data.price - refAmount;
        }

        // Transfer payment
        if (data.tokenAddress == address(0)) {
            require(msg.value >= data.price, "Not enough money");
            (bool success, ) = fundAddress.call{value: price}("");
            require(success, "Transfer payment to admin failed");
            if (refAmount != 0) {
                (success, ) =  data.refAddress.call{value: refAmount}("");
                require(success, "Transfer payment to ref failed");
            }
        } else {
            IERC20(data.tokenAddress).transferFrom(
                msg.sender,
                fundAddress,
                price
            );
            if (refAmount != 0) {
                IERC20(data.tokenAddress).transferFrom(
                    msg.sender,
                    data.refAddress,
                    refAmount
                );
            }
        }
        uint256 mintIndex = totalSupply() + 1000001;
        _safeMint(_msgSender(), mintIndex);
        _setTokenURI(mintIndex, data.uri);

        emit BuyEvent(
            _msgSender(),
            data.id,
            mintIndex,
            data.nonce,
            data.tokenAddress,
            data.price,
            uint64(block.timestamp)
        );
    }
    
    function setFundAddress(address _fundAddress) external onlyOwner {
        fundAddress = _fundAddress;
    }
    
}
