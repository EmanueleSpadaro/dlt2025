// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {RoleBased} from "./RoleBased.sol";

// ERC721 Standard
// • Role-based Transferability: this token can be transferred with some limitation based on the
// purpose of the case. It can be transferred to minter to membership holder and between membership
// holders. In this particular case the membership holder is also the minter. This token cannot be
// transferred to token holder since is required to be a member of the community in order to
// participate
// • Temporary Transfer: The transfer of the token is specifically linked to the act of borrowing an
// item. When an item is borrowed, the corresponding non fungible token is transferred to the
// borrower's account for the duration of the borrowing period.

contract PhysicalObjectRepresentation is ERC721, RoleBased {
    uint256 private _nextTokenId;
    string private _baseTokenURI;

    // Borrowing functionality
    struct Borrowing {
        address originalOwner;
        uint256 borrowEndTime;
        bool isBorrowed;
    }

    // Mapping from token ID to borrowing info
    mapping(uint256 => Borrowing) private _borrowings;

    // Role constants - assuming these roles exist in the registry
    bytes32 public constant MEMBERSHIP_ROLE = keccak256("MEMBERSHIP_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("PHYSICAL_REPRESENTATIONS_MINTER_ROLE");

    constructor(
        address registry
    ) RoleBased(registry) ERC721("PhysicalObject", "POBJ") {
        // Allow transfers from minters to members
        transferCoupling[MINTER_ROLE][MEMBERSHIP_ROLE] = true;
        // Allow transfers between members
        transferCoupling[MEMBERSHIP_ROLE][MEMBERSHIP_ROLE] = true;

        // Set up minter role as issuer
        _addIssuer(MINTER_ROLE);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        address from = _ownerOf(tokenId);

        // Allow minting (transfer from zero address)
        if (from == address(0)) {
            return super._update(to, tokenId, auth);
        }

        // Handle return of borrowed items
        if (
            _borrowings[tokenId].isBorrowed &&
            to == _borrowings[tokenId].originalOwner
        ) {
            // Return the item to original owner
            _borrowings[tokenId].isBorrowed = false;
            return super._update(to, tokenId, auth);
        }

        // Check if borrowing period has ended and force return if needed
        if (
            _borrowings[tokenId].isBorrowed &&
            _borrowings[tokenId].borrowEndTime < block.timestamp
        ) {
            to = _borrowings[tokenId].originalOwner;
            _borrowings[tokenId].isBorrowed = false;
            return super._update(to, tokenId, auth);
        }

        // Check role-based transfer restrictions
        require(
            _canTransfer(from, to),
            "Transfer not allowed between these roles"
        );

        return super._update(to, tokenId, auth);
    }

    function safeMint(address to) public {
        require(_issuer(msg.sender), "Not issuer");
        // Make sure recipient has membership
        require(
            registry.hasRole(MEMBERSHIP_ROLE, to),
            "Recipient must be a member"
        );

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    // Allow a member to borrow an item for a specified duration
    function borrowItem(
        uint256 tokenId,
        address borrower,
        uint256 durationInSeconds
    ) external {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Only owner can lend item");
        require(
            registry.hasRole(MEMBERSHIP_ROLE, borrower),
            "Borrower must be a member"
        );
        require(!_borrowings[tokenId].isBorrowed, "Item already borrowed");

        // Store original owner and borrowing end time
        _borrowings[tokenId].originalOwner = owner;
        _borrowings[tokenId].borrowEndTime =
            block.timestamp +
            durationInSeconds;
        _borrowings[tokenId].isBorrowed = true;

        // Transfer the token to the borrower
        _transfer(owner, borrower, tokenId);
    }

    // Allow borrower to return an item before the borrowing period ends
    function returnItem(uint256 tokenId) external {
        require(_borrowings[tokenId].isBorrowed, "Item not borrowed");
        require(
            msg.sender == ownerOf(tokenId),
            "Only current holder can return"
        );

        address originalOwner = _borrowings[tokenId].originalOwner;
        _borrowings[tokenId].isBorrowed = false;

        // Return the token to the original owner
        _transfer(msg.sender, originalOwner, tokenId);
    }

    // Check borrowing status
    function isBorrowed(uint256 tokenId) external view returns (bool) {
        return _borrowings[tokenId].isBorrowed;
    }

    // Get borrowing info
    function getBorrowingInfo(
        uint256 tokenId
    )
        external
        view
        returns (address owner, uint256 endTime, bool borrowed)
    {
        require(_exists(tokenId), "Token does not exist");
        Borrowing memory borrowing = _borrowings[tokenId];
        return (
            borrowing.originalOwner,
            borrowing.borrowEndTime,
            borrowing.isBorrowed
        );
    }

    // Helper function to check if a token exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function setBaseURI(string memory baseURI) external {
        require(_issuer(msg.sender), "Not issuer");
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
