// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IRegistry} from "./IRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract RoleBased is Ownable {
    event IssuerTypeAdded(bytes32 indexed _type);
    event IssuerTypeRemoved(bytes32 indexed _type);

    IRegistry registry;
    mapping(bytes32 => bool) public isIssuer;

    //From Role to Role transfer check mapping
    mapping(bytes32 => mapping(bytes32 => bool)) public transferCoupling;

    constructor(address _registry) Ownable(msg.sender) {
        require(
            ERC165Checker.supportsInterface(
                _registry,
                type(IRegistry).interfaceId
            ),
            "registry not erc165 compliant"
        );
        registry = IRegistry(_registry);
    }

    function addIssuer(bytes32 _issuerType) external onlyOwner {
       _addIssuer(_issuerType);
    }

    function removeIssuer(bytes32 _issuerType) external onlyOwner {
       _removeIssuer(_issuerType);
    }

     function _addIssuer(bytes32 _issuerType) internal {
        isIssuer[_issuerType] = true;
        emit IssuerTypeAdded(_issuerType);
    }

    function _removeIssuer(bytes32 _issuerType) internal {
        isIssuer[_issuerType] = false;
        emit IssuerTypeRemoved(_issuerType);
    }

    function _issuer(address _acc) internal view returns (bool) {
        bytes32[] memory roles = registry.getRolesOf(_acc);
        for (uint i = 0; i < roles.length; i++) {
            if (isIssuer[roles[i]]) {
                return true;
            }
        }
        return false;
    }

    function _canTransfer(
        address _from,
        address _to
    ) internal virtual view returns (bool) {
        bytes32[] memory fromRoles = registry.getRolesOf(_from);
        bytes32[] memory toRoles = registry.getRolesOf(_to);
        for (uint i = 0; i < fromRoles.length; i++) {
            bytes32 fromRole = fromRoles[i];
            for (uint j = 0; i < toRoles.length; j++) {
                bytes32 toRole = toRoles[j];
                if (transferCoupling[fromRole][toRole]) {
                    return true;
                }
            }
        }
        return false;
    }
}
