// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
// 6.2. Tokenized Civic Participation
// Category: This token is designed to support activities that promote civic participation, serving as a
// means to recognize and reward community members for their engagement in collective actions. Its
// value proposition lies in transforming civic engagement from an often unrewarded effort into one that
// is acknowledged, incentivized, and empowering for participants.In this context, a specific organization
// can issue a token tailored to reward a defined civic activity.
// • ERC20 Standard
// • Role-based Minting: The ability to mint tokens is assigned to specific roles—such as organizations
// —who act as authorized issuers within the system.
// • Role-based Transferability: this token can be transferred with some limitation based on the
// purpose of the case. It can be transferred from minter to token holder, but not between token
// holders.

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RoleBased} from "./RoleBased.sol";

contract TokenizedCivic is ERC20, RoleBased {
    constructor(
        string memory name,
        string memory symbol,
        address _registry
    ) ERC20(name, symbol) RoleBased(_registry) {
    }

    //In this specific instance of token, we can just check that only one is an issuer
    function _canTransfer(
        address _from,
        address _to
    ) internal override view returns (bool) {
        return _issuer(_from) != _issuer(_to);
    }

    function mint(address to, uint256 amount) external {
        require(_issuer(_msgSender()), "Not authorized to mint");
        _mint(to, amount);
    }

    function transfer(
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        require(_canTransfer(_msgSender(), to), "transfer not authorized");
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }
}