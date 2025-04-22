//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IRegistry {
    function getRoles() external view returns(bytes32[] memory);

    function getRolesOf(address account) external view returns(bytes32[] memory);

    function hasRole(bytes32 role, address account) external view returns (bool);
}