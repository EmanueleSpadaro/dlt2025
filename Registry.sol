// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IRegistry} from "./IRegistry.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract Registry is ERC165, IRegistry, AccessControl, Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.Bytes32Set private roles;
    mapping(bytes32 => EnumerableSet.AddressSet) roleUsers;
    mapping(address => EnumerableSet.Bytes32Set) userRoles;

    constructor() Ownable(msg.sender) {}
    
    function hasRole(bytes32 role, address account) public view override(AccessControl, IRegistry) returns (bool) {
        return super.hasRole(role, account);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, AccessControl) returns (bool) {
        return
            interfaceId == type(IRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _roleExists(bytes32 role) internal view returns (bool) {
        return roles.contains(role);
    }

    function _addRole(bytes32 role) internal {
        require(!_roleExists(role), "already existing role");
        roles.add(role);
    }

    function _removeRole(bytes32 role) internal {
        require(_roleExists(role), "non existing role");

        //We delete the role from all users
        EnumerableSet.AddressSet storage members = roleUsers[role];
        //Warning, here we implement the manual remove for Proof Of Concept @ https://docs.openzeppelin.com/contracts/5.x/api/utils#EnumerableSet
        for (uint i = 0; i < members.length(); i++) {
            address member = members.at(i);
            //Other than zeroing out the EnumerableSet, we revoke the OpenZeppelin's role & the role from the user's role set
            _revokeRole(role, member);
            members.remove(member);
            userRoles[member].remove(role);
        }
        //We finally remove the role from the Registry ones
        roles.remove(role);
    }

    function grantRole(
        bytes32 role,
        address account
    ) public override(AccessControl) {
        require(!hasRole(role, account), "account already has role");
        roleUsers[role].add(account);
        userRoles[account].add(role);
        _grantRole(role, account);
    }

    function revokeRole(
        bytes32 role,
        address account
    ) public override(AccessControl) {
        require(!hasRole(role, account), "account already missed such role");
        roleUsers[role].remove(account);
        userRoles[account].remove(role);
        _revokeRole(role, account);
    }

    function getRoles() external view returns (bytes32[] memory) {
        return roles.values();
    }

    function getRolesOf(
        address account
    ) external view returns (bytes32[] memory) {
        return userRoles[account].values();
    }
}
