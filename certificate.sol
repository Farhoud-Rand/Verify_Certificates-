// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract certificateNFT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, AccessControl, ReentrancyGuard {
    // Define roles
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Variable to make the contract auto Increment Ids for tokens
    uint256 private _nextTokenId;
    //-----------------------------------------------------------------
    // Constructor
    //-----------------------------------------------------------------
    constructor() ReentrancyGuard() ERC721("Rand Collection", "RC") {
        // Give the contract depolyer admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    //-----------------------------------------------------------------
    // Admin Functionality
    //-----------------------------------------------------------------
    function assignRole(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
        if(role != ADMIN_ROLE && role != ISSUER_ROLE) {
            revert("Error: Invalid role");
        } else {
            _grantRole(role, account);
        }
    }

    function revokeRoleFromUser(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
        if(role != ADMIN_ROLE && role != ISSUER_ROLE) {
            revert("Error: Invalid role");
        } else {
            _revokeRole(role, account);
        }
    }
    //-----------------------------------------------------------------
    // Issuer Functionality
    //-----------------------------------------------------------------
    // Minting tokens
    function safeMint(address _to, string calldata _uri) external onlyRole(ISSUER_ROLE) nonReentrant(){
        uint256 tokenId = _nextTokenId++;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
    }

    // Burning tokens 
    function burnToken(uint256 tokenId) public onlyRole(ISSUER_ROLE) nonReentrant() {
        _burn(tokenId);
    }

    //-----------------------------------------------------------------
    // Viewer and beneficiary Functionality
    //-----------------------------------------------------------------
    function unsafe_inc(uint x) private pure returns(uint) {
        unchecked { return x+1; }
    }

    function getTokens(address account) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(account);
        uint256[] memory ownedTokens = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i = unsafe_inc(i)) {
            ownedTokens[i] = tokenOfOwnerByIndex(account, i);
        }
        return ownedTokens;
    }
    //-----------------------------------------------------------------
    // The following functions are overrides required by Solidity
    // Function that retrieves the metadata URI associated with a given tokenId
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // Function that checks whether a given interfaceId is supported by the contract and returns a boolean value accordingly 
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }  

    // This is an internal function to update balance or ownership
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    // This is an internal function to increase balance
    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }
}