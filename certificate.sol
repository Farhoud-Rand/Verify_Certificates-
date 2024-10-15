// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721, ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// Admin -> 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

// issuer1 -> 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// deleted issuer2 -> 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db

// viewer 1 -> 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678
// viewer 2 -> 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7

// token 1 to 0x617F2E2fD72FD9D5503197092aC168c91465E7f2 (false)
// token 2 to 0x17F6AD8Ef982297579C203069C1DbfFE4348c372 (false)
// token 3 to 0x17F6AD8Ef982297579C203069C1DbfFE4348c372 (true)

contract MyToken is ERC721, ERC721Enumerable, AccessControl {
    // Define roles
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VIEWER_ROLE = keccak256("VIEWER_ROLE");
    
    // Struct to store certificate information
    // Todo: add expiration functionality
    struct Certificate{
        int id;
        string name;
        string reg_no;
        string grad_date;
        string spec;
        address superAddress;
        string degree;
        string pdflink;
        bool certStatus; // We can use this boolean to indicate if the certificate is expired or not 
    }

    // Struct to store token data
    struct TokenData {
        Certificate certificate;      // Use certificate struct instead of string data
        address beneficiary;          // Owner address
        bool isPublic;                // Visibility flag
    }

    // Events for tracking access requests and approvals
    event AccessRequested(address indexed viewer, address indexed beneficiary, uint256 tokenId);
    event AccessApproved(address indexed beneficiary, address indexed viewer, uint256 tokenId);
    event AccessRevoked(address indexed beneficiary, address indexed viewer, uint256 tokenId);
    event VisibilityUpdated(uint256 tokenId, bool isPublic);
    
    // Mapping from tokenId to token data
    mapping(uint256 => TokenData) private _tokenData;
    // mapping(uint256 => TokenData) public _tokenData;

    // Mapping from beneficiary to viewer permissions
    mapping(address => mapping(address => bool)) private _approvedViewers;
    // mapping(address => mapping(address => bool)) public _approvedViewers;
   
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

    modifier onlyOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You must be the token owner");
        _;
    }

    constructor() ERC721("MyToken", "TKN") {
        // Grant the minter role to a specified account
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //-----------------------------------------------------------------
    // Admin (deployer) Functionality
    //-----------------------------------------------------------------
    function assignRole(bytes32 role, address account) public onlyAdmin {
        // bytes32 ENTERED_ROLE = keccak256(abi.encodePacked(role));
        _grantRole(role, account);
    }

    function revokeRoleFromUser(bytes32 role, address account) public onlyAdmin {
        _revokeRole(role, account);
    }

    //-----------------------------------------------------------------
    // Issuer Functionality
    //-----------------------------------------------------------------
    // Minting tokens
    function mintToken(address to, uint256 tokenId, Certificate memory certificate, bool isPublic) public onlyIssuer {
        _safeMint(to, tokenId);
        _tokenData[tokenId] = TokenData(certificate, to, isPublic);
    }

    // Burning tokens 
    function burnToken(uint256 tokenId) public onlyIssuer {
        _burn(tokenId);
        delete _tokenData[tokenId];
    }

    // Updating token data
    function updateTokenData(uint256 tokenId, Certificate memory newData) public onlyIssuer {
        // Check if token is exist or not 
        address owner = ownerOf(tokenId);
        require(owner != address(0), "Token does not exist");
        _tokenData[tokenId].certificate = newData;
    }

   //-----------------------------------------------------------------
    // Beneficiary Functionality
    //-----------------------------------------------------------------
    // Beneficiary can update visibility of their token data
    function updateVisibility(uint256 tokenId, bool isPublic) public onlyOwner(tokenId) {
        _tokenData[tokenId].isPublic = isPublic;
        emit VisibilityUpdated(tokenId, isPublic);
    }

    // Beneficiary approves a viewer to access their data
    function approveAccess(uint256 tokenId, address viewer) public onlyOwner(tokenId) {
        require(!_approvedViewers[msg.sender][viewer], "Viewer is already approved");
       
        _approvedViewers[msg.sender][viewer] = true;
        emit AccessApproved(msg.sender, viewer, tokenId);
    }

    // Beneficiary revokes access from a viewer
    function revokeAccess(uint256 tokenId, address viewer) public onlyOwner(tokenId) {
        require(_approvedViewers[msg.sender][viewer], "Viewer is not approved");

        _approvedViewers[msg.sender][viewer] = false;
        emit AccessRevoked(msg.sender, viewer, tokenId);
    }

    // Beneficiary function to view all their tokens
    function getMyTokens() public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(msg.sender);
        uint256[] memory ownedTokens = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            ownedTokens[i] = tokenOfOwnerByIndex(msg.sender, i);
        }

        return ownedTokens;
    }
    //-----------------------------------------------------------------
    // Viewer Functionality
    //-----------------------------------------------------------------
    // Viewer checks if they can view data
    function viewDataAsViewer(uint256 tokenId) public onlyViewer view returns (Certificate memory) {
        // Check if token is exist or not 
        address owner = ownerOf(tokenId);
        require(owner != address(0), "Token does not exist");

        TokenData memory tokenData = _tokenData[tokenId];
        if (tokenData.isPublic || _approvedViewers[tokenData.beneficiary][msg.sender]) {
            return tokenData.certificate;
        } else {
            revert("Access denied: Data is private and requires permission from the beneficiary");
        }
    }

    // Viewer requests permission to view private data
    function requestAccess(uint256 tokenId) public onlyViewer {
        require(!_tokenData[tokenId].isPublic, "Data is already public");

        address beneficiary = _tokenData[tokenId].beneficiary;
        require(beneficiary != address(0), "No beneficiary assigned to this token");

        emit AccessRequested(msg.sender, beneficiary, tokenId);
    }
    
    //-----------------------------------------------------------------
    // Resolve conflict 
    // Override _increaseBalance to resolve the inheritance issue
    function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);  
    }

     // Override _update to resolve conflict
    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    // Override supportsInterface to resolve inheritance issues
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}