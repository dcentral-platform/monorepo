// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title DCentralNFT
 * @dev Implementation of the DCentral NFT contract
 * @custom:security-contact security@dcentral.io
 */
contract DCentralNFT is ERC721URIStorage, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    // Token ID counter
    Counters.Counter private _tokenIdCounter;
    
    // Base URI for metadata
    string private _baseTokenURI;
    
    // Maximum supply of tokens
    uint256 public maxSupply = 10000;
    
    // Minting price
    uint256 public mintPrice = 0.05 ether;
    
    // Mapping for royalty information
    mapping(uint256 => uint256) private _tokenRoyalties;
    
    // Default royalty percentage (500 = 5%)
    uint256 public defaultRoyaltyPercentage = 500;
    
    // Maximum royalty percentage (1000 = 10%)
    uint256 public maxRoyaltyPercentage = 1000;
    
    // Governance token address
    address public governanceToken;
    
    // Events
    event Minted(address indexed to, uint256 indexed tokenId, string tokenURI);
    event RoyaltyUpdated(uint256 indexed tokenId, uint256 royaltyPercentage);
    event BaseURIUpdated(string newBaseURI);
    event MintPriceUpdated(uint256 newPrice);
    event GovernanceTokenUpdated(address newGovernanceToken);
    
    /**
     * @dev Constructor initializes the NFT contract
     * @param name The name of the NFT collection
     * @param symbol The symbol of the NFT collection
     * @param baseTokenURI The base URI for token metadata
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }
    
    /**
     * @dev Mint a new NFT
     * @param to The address to mint the NFT to
     * @param tokenURI The token URI for the NFT metadata
     * @return tokenId The ID of the newly minted token
     */
    function mint(address to, string memory tokenURI) 
        public 
        payable 
        nonReentrant 
        returns (uint256) 
    {
        require(_tokenIdCounter.current() < maxSupply, "Max supply reached");
        require(msg.value >= mintPrice, "Insufficient payment");
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _tokenRoyalties[tokenId] = defaultRoyaltyPercentage;
        
        emit Minted(to, tokenId, tokenURI);
        
        return tokenId;
    }
    
    /**
     * @dev Set the royalty percentage for a specific token
     * @param tokenId The ID of the token
     * @param royaltyPercentage The royalty percentage (100 = 1%)
     */
    function setTokenRoyalty(uint256 tokenId, uint256 royaltyPercentage) 
        external 
        onlyOwner 
    {
        require(_exists(tokenId), "Token does not exist");
        require(royaltyPercentage <= maxRoyaltyPercentage, "Royalty too high");
        
        _tokenRoyalties[tokenId] = royaltyPercentage;
        
        emit RoyaltyUpdated(tokenId, royaltyPercentage);
    }
    
    /**
     * @dev Get the royalty information for a token
     * @param tokenId The ID of the token
     * @return receiver The royalty receiver address
     * @return royaltyAmount The royalty amount
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) 
        external 
        view 
        returns (address receiver, uint256 royaltyAmount) 
    {
        require(_exists(tokenId), "Token does not exist");
        
        uint256 royaltyPercentage = _tokenRoyalties[tokenId];
        uint256 amount = (salePrice * royaltyPercentage) / 10000;
        
        return (owner(), amount);
    }
    
    /**
     * @dev Set the base URI for all token metadata
     * @param newBaseURI The new base URI
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        
        emit BaseURIUpdated(newBaseURI);
    }
    
    /**
     * @dev Set the mint price
     * @param newPrice The new mint price
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        
        emit MintPriceUpdated(newPrice);
    }
    
    /**
     * @dev Set the governance token address
     * @param newGovernanceToken The new governance token address
     */
    function setGovernanceToken(address newGovernanceToken) external onlyOwner {
        governanceToken = newGovernanceToken;
        
        emit GovernanceTokenUpdated(newGovernanceToken);
    }
    
    /**
     * @dev Withdraw contract funds to owner
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Override base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
     * @dev Required override for inherited contracts
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    /**
     * @dev Required override for inherited contracts
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Required override for token URI storage
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    /**
     * @dev Required override for burning
     */
    function _burn(uint256 tokenId) 
        internal 
        override(ERC721, ERC721URIStorage) 
    {
        super._burn(tokenId);
        delete _tokenRoyalties[tokenId];
    }
}