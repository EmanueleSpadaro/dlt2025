// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RoleBased} from "./RoleBased.sol";

contract Coupon is ERC20, RoleBased {
    event CouponsRedeemed(
        address indexed user,
        uint256 amount,
        address indexed issuer
    );

    constructor(
        string memory name,
        string memory symbol,
        address _registry
    ) ERC20(name, symbol) RoleBased(_registry) {}

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
        //If the coupon is being transferred to an issuer, we assume the transaction is a redemption
        // and therefore we burn the tokens instead of transferring them.
        if (_issuer(to)) {
            _burn(owner, value);
            emit CouponsRedeemed(owner, value, to);
            return true;
        }
        // Otherwise, we proceed with the normal transfer
        _transfer(owner, to, value);
        return true;
    }
}
