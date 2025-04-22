// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 6.4. Badge
// Category: It is an artifact—a unique, non-fungible token (NFT) recorded on the blockchain—used to
// certify the completion of a task. In a community context, this NFT serve to represent achievement
// and merit. Badges are verifiable proof of participation,confirming that an individual has carried out a
// specific activity, attended an event, or been present at a designated location
// Characteristics:
// • ERC721 Standard
// • Role-based Minting: Only designated accounts have the permission to create badges.
// • Role-based Transferability: this token can be transferred from issuer to citizen. Badges cannot be
// transferred from citizen to citizen and from citizen to issuer
// • Unique Acquisition per Account: An individual account can only earn a specific badge once from
// the issuing entity.
// • Task-Based Acquisition: Badges are awarded upon the completion of specific tasks or task
// sequences, or as proof of presence at designated events or locations.
// • Additionally, the badge can be designed with two possible functionalities:
// – Burnable for Additional Rewards: Users may choose to burn multiple collected badges in
// exchange for further rewards or benefits.
// – Collectible as Proof of Presence or Achievement: Alternatively, badges may serve as im-
// mutable proof of participation, presence, or task accomplishment, contributing to a user’s
// reputation or history within the system.

import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {RoleBased} from "./RoleBased.sol";

contract Badge is ERC721URIStorage, ERC721Burnable, RoleBased {

    // Token ID tracker
    uint private _tokenIdCounter;

    // Mapping badge types to recipients (badgeType => address => bool)
    mapping(uint256 => mapping(address => bool)) private _hasBadge;

    // Mapping tokenId to badge type
    mapping(uint256 => uint256) private _badgeTypes;

    // Optional mapping to mark badges as burnable
    mapping(uint256 => bool) private _isBurnable;

    constructor(
        string memory name,
        string memory symbol,
        address registry
    ) ERC721(name, symbol) RoleBased(registry) {}

    /// @notice Mint a badge with metadata to a user.
    function mintBadge(
        address to,
        uint256 badgeType,
        bool burnable,
        string memory ipfsCID
    ) external {
        require(_issuer(_msgSender()), "not issuer");
        require(!_hasBadge[badgeType][to], "User already owns this badge");

        uint256 tokenId = _tokenIdCounter++;

        _safeMint(to, tokenId);

        _badgeTypes[tokenId] = badgeType;
        _hasBadge[badgeType][to] = true;
        _isBurnable[tokenId] = burnable;

        _setTokenURI(tokenId, ipfsCID);
    }

    /// @notice Restricted transfer implementation using _update hook
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721) returns (address) {
        address from = _ownerOf(tokenId);

        // Skip transfer restrictions for minting and burning
        if (from != address(0) && to != address(0)) {
            require(
                _canTransfer(from, to),
                "Only approved transfers allowed"
            );
        }

        return super._update(to, tokenId, auth);
    }

    /// @notice Burn only if badge is burnable
    function burn(uint256 tokenId) public override {
        require(_isBurnable[tokenId], "Badge is not burnable");

        address owner = _ownerOf(tokenId);
        uint256 badgeType = _badgeTypes[tokenId];

        super.burn(tokenId);

        _hasBadge[badgeType][owner] = false;
    }

    /// @notice Returns full IPFS URI
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return string(abi.encodePacked("ipfs://", uri));
    }

    // ========= View Helpers =========

    function hasBadge(
        address user,
        uint256 badgeType
    ) external view returns (bool) {
        return _hasBadge[badgeType][user];
    }

    function isBurnable(uint256 tokenId) external view returns (bool) {
        return _isBurnable[tokenId];
    }

    function badgeTypeOf(uint256 tokenId) external view returns (uint256) {
        return _badgeTypes[tokenId];
    }

    function ipfsCIDOf(uint256 tokenId) external view returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
