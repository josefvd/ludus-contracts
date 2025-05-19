// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILudusEventsOracle.sol";

contract LudusIdentity is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId; // Using a simple uint256 for token IDs, 0-indexed
    uint256 public constant MAX_SUPPLY = 10000;
    ILudusEventsOracle public ludusEventsOracle;

    event IdentityMinted(uint256 indexed tokenId, address indexed owner, string tokenURI);

    constructor(
        address initialOwner,
        address _ludusEventsOracleAddress
    )
        ERC721("Ludus Simplified Identity", "LSI") // ERC721 constructor
        Ownable(initialOwner) // Ownable constructor
    {
        require(_ludusEventsOracleAddress != address(0), "Oracle address cannot be zero");
        ludusEventsOracle = ILudusEventsOracle(_ludusEventsOracleAddress);
        _nextTokenId = 0; // Initialize for 0-indexed token IDs (0 to MAX_SUPPLY - 1)
    }

    function setLudusEventsOracle(address _ludusEventsOracleAddress) external onlyOwner {
        require(_ludusEventsOracleAddress != address(0), "Oracle address cannot be zero");
        ludusEventsOracle = ILudusEventsOracle(_ludusEventsOracleAddress);
    }

    function mintIdentity(address recipient, string memory _tokenURI) external onlyOwner returns (uint256) {
        require(ludusEventsOracle.getCompletedEventCount() >= 3, "Condition: Less than 3 events completed");
        
        uint256 currentTokenId = _nextTokenId;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000001,currentTokenId)}
        require(currentTokenId < MAX_SUPPLY, "Max supply reached");

        _nextTokenId++; // Increment for the next mint
        
        _safeMint(recipient, currentTokenId);
        _setTokenURI(currentTokenId, _tokenURI);

        emit IdentityMinted(currentTokenId, recipient, _tokenURI);
        return currentTokenId;
    }

    // ERC721URIStorage overrides ERC721.tokenURI, so we override ERC721URIStorage's version.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00220000, 1037618708514) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00220001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00221000, tokenId) }
        return super.tokenURI(tokenId);
    }

    // ERC721URIStorage overrides ERC721.supportsInterface, so we override ERC721URIStorage's version.
    // However, Ownable also has supportsInterface. If ERC721URIStorage doesn't inherit from Ownable (it doesn't directly)
    // and both ERC721URIStorage (via ERC721) and Ownable are bases of LudusIdentity, we need to specify both.
    // Let's check OZ source: ERC721URIStorage -> ERC721 -> ERC165.
    // Ownable -> Context (no ERC165).
    // So, the conflict for supportsInterface would be between ERC721 (base of URIStorage) and any other base that implements it.
    // In this setup, ERC721URIStorage is the most derived contract in its line that implements supportsInterface (via ERC721).
    // Ownable does not implement supportsInterface.
    // Therefore, just overriding ERC721URIStorage (which implicitly overrides ERC721's) should be fine.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage) // This should be sufficient as ERC721URIStorage inherits ERC721's supportsInterface
        returns (bool)
    {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00260000, 1037618708518) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00260001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00261000, interfaceId) }
        // It's important that ERC721URIStorage's supportsInterface function correctly calls super.supportsInterface()
        // or handles all interfaces including those from its own bases (like IERC721URIStorage if it had one).
        // OpenZeppelin contracts are usually structured to handle this correctly.
        return super.supportsInterface(interfaceId);
    }
} 