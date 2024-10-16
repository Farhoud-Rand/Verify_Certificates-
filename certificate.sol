// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract certificateNFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable, AccessControl {
    // Define roles
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VIEWER_ROLE = keccak256("VIEWER_ROLE");

    //-----------------------------------------------------------------
    // Modifiers for access control
    //-----------------------------------------------------------------
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can call this function");
        _;
    }

    modifier onlyIssuer() {
        require(hasRole(ISSUER_ROLE, msg.sender), "Only issuer can call this function");
        _;
    }

    modifier onlyViewer() {
        require(hasRole(VIEWER_ROLE, msg.sender), "You must be a viewer");
        _;
    }

    //-----------------------------------------------------------------
    // Constructor
    //-----------------------------------------------------------------
    constructor() ERC721("Rand Collection", "RC") Ownable(msg.sender) {
        // Give the contract depolyer admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //-----------------------------------------------------------------
    // Admin Functionality
    //-----------------------------------------------------------------
    function assignRole(string memory role, address account) public onlyAdmin {
        bytes32 enteredRole = keccak256(abi.encodePacked(role));
        if(enteredRole != VIEWER_ROLE && enteredRole != ADMIN_ROLE && enteredRole != ISSUER_ROLE) {
            revert("Error: Invalid role");
        } else {
            _grantRole(enteredRole, account);
        }
    }

    function revokeRoleFromUser(string memory role, address account) public onlyAdmin {
        bytes32 enteredRole = keccak256(abi.encodePacked(role));
        if(enteredRole != VIEWER_ROLE && enteredRole != ADMIN_ROLE && enteredRole != ISSUER_ROLE) {
            revert("Error: Invalid role");
        } else {
            _revokeRole(enteredRole, account);
        }
    }

    //-----------------------------------------------------------------
    // Issuer Functionality
    //-----------------------------------------------------------------
    // Minting tokens
    function safeMint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _uri);
    }

    // Burning tokens 
    function burnToken(uint256 tokenId) public onlyIssuer {
        burn(tokenId);
    }
    
    //-----------------------------------------------------------------
    // The following functions are overrides required by Solidity
    // Function that retrieves the metadata URI associated with a given tokenId
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // This function checks whether a given interfaceId is supported by the contract and returns a boolean value accordingly 
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage,AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }   
}