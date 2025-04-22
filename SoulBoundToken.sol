// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {RoleBased} from "./RoleBased.sol";

// • ERC721 Standard
// • Role-based Minting: The ability to mint tokens is assigned to specific roles, such as an organization
// representing the community, who act as minter and admin within the system.
// • Role-based Transferability: The token can be transferred only from the minter to the token holder,
// and its transferability is strictly tied to community membership. Once a token holder becomes
// a recognized member of the community, they receive the SBT (Soulbound Token), which is
// non-transferable and permanently linked to their account, making a role transition from token
// holder to membership holder

contract Soulbound is ERC721, RoleBased {
    uint256 private _nextTokenId;

    string private _baseTokenURI;

    constructor(
        address initialOwner,
        address registry
    ) RoleBased(registry) ERC721("SoulBound", "SBT") {}

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        address from = _ownerOf(tokenId);

        // Only allow minting (transfer from zero address)
        // Block all other transfers
        // NOTICE: in the provided source code, _canTransfer is not overridden nor used 
        if (from != address(0)) {
            revert("Token not transferable");
        }

        return super._update(to, tokenId, auth);
    }

    function safeMint(address to) public {
        require(_issuer(msg.sender), "not issuer");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    function setBaseURI(string memory baseURI) external {
        require(_issuer(msg.sender), "not issuer");
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string.concat(baseURI, Strings.toString(tokenId))
                : "";
    }
}
