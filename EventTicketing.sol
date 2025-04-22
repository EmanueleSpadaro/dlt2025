// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ERC721 Standard
// • Role-based Minting: The ability to mint tokens is assigned to specific roles—such as associations
// or local retailers—who act as authorized issuers within the system.
// • Role-based Transferability: this token can be transferred with some limitation based on the
// purpose of the case. It can be transferred from minter to token holder and from token holder to
// burner, token holder to validator but not between token holders.
// • Lifecycle Options:
// – Burnable: Tickets are burned either after they are used for the event entrance or once the
// event has expired. In this case when it is transferred from a membership holder or a token
// holder to the burner
// – Collectible NFT: Tickets are not burnt, serving as collector's items or memorabilia

import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {RoleBased} from "./RoleBased.sol";

contract EventTicketing is ERC721URIStorage, ERC721Burnable, RoleBased {
    // Token ID tracker
    uint private _tokenIdCounter;

    // Mapping ticket types to recipients (ticketType => address => bool)
    mapping(uint256 => mapping(address => bool)) private _hasTicket;

    // Mapping tokenId to ticket type
    mapping(uint256 => uint256) private _ticketTypes;

    // Enables us to bind the ticket on validation or burn it
    mapping(uint256 => bool) private _isBurnable;

    // Mapping for validator roles
    mapping(bytes32 => bool) private isValidator;
    mapping(uint256 => bool) private isValidated;

    event ValidatorTypeAdded(bytes32 role);
    event ValidatorTypeRemoved(bytes32 role);

    constructor(
        string memory name,
        string memory symbol,
        address registry
    ) ERC721(name, symbol) RoleBased(registry) {}

    function _addValidator(bytes32 _validatorType) internal {
        isValidator[_validatorType] = true;
        emit ValidatorTypeAdded(_validatorType);
    }

    function _removeValidator(bytes32 _validatorType) internal {
        isValidator[_validatorType] = false;
        emit ValidatorTypeRemoved(_validatorType);
    }

    function addValidator(bytes32 _validatorType) public onlyOwner {
        _addValidator(_validatorType);
    }

    function removeValidator(bytes32 _validatorType) public onlyOwner {
        _removeValidator(_validatorType);
    }

    function _validator(address _acc) internal view returns (bool) {
        bytes32[] memory roles = registry.getRolesOf(_acc);
        for (uint i = 0; i < roles.length; i++) {
            if (isValidator[roles[i]]) {
                return true;
            }
        }
        return false;
    }

    //Used to prevent the transfer in the _update method
    function _ticketBound(uint256 tokenId) private view returns (bool) {
        address owner = _ownerOf(tokenId);
        uint256 ticketType = _ticketTypes[tokenId];
        return isValidated[tokenId] && _hasTicket[ticketType][owner];
    }

    function validate(uint256 tokenId) public {
        require(!isValidated[tokenId], "ticket already validated");
        require(_validator(_msgSender()), "Only validators can validate");
        address owner = _ownerOf(tokenId);
        uint256 ticketType = _ticketTypes[tokenId];

        isValidated[tokenId] = true;

        // If burnable, burn after validating
        if (_isBurnable[tokenId]) {
            super.burn(tokenId);
            _hasTicket[ticketType][owner] = false;
        }
    }

    function mintTicket(
        address to,
        uint256 ticketType,
        bool burnable,
        string memory ipfsCID
    ) external {
        require(_issuer(_msgSender()), "not issuer");
        require(!_hasTicket[ticketType][to], "User already owns this ticket");

        uint256 tokenId = _tokenIdCounter++;

        _safeMint(to, tokenId);

        _ticketTypes[tokenId] = ticketType;
        _hasTicket[ticketType][to] = true;
        _isBurnable[tokenId] = burnable;

        _setTokenURI(tokenId, ipfsCID);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721) returns (address) {
        address from = _ownerOf(tokenId);

        // Skip transfer restrictions for minting and burning
        if (from != address(0) && to != address(0)) {
            // Prevent transfer of bound tickets
            require(
                !_ticketBound(tokenId),
                "Ticket is validated and bound to owner"
            );

            // Check role-based transfer permissions
            require(_canTransfer(from, to), "Only approved transfers allowed");
        }

        return super._update(to, tokenId, auth);
    }

    function burn(uint256 tokenId) public override {
        require(_isBurnable[tokenId], "ticket is not burnable");

        address owner = _ownerOf(tokenId);
        uint256 ticketType = _ticketTypes[tokenId];

        super.burn(tokenId);

        _hasTicket[ticketType][owner] = false;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return string(abi.encodePacked("ipfs://", uri));
    }

    // ========= View Helpers =========

    function hasTicket(
        address user,
        uint256 ticketType
    ) external view returns (bool) {
        return _hasTicket[ticketType][user];
    }

    function isBurnable(uint256 tokenId) external view returns (bool) {
        return _isBurnable[tokenId];
    }

    function ticketTypeOf(uint256 tokenId) external view returns (uint256) {
        return _ticketTypes[tokenId];
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
