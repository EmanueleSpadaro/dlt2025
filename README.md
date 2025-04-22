# Token‑Based Community Toolkit

A reference implementation of monetary and non‑monetary incentive tokens and a modular role registry for role-based governed collaborative economies in local communities. This toolkit provides solidity smart contracts of various token constructs alongside a registry that assigns roles and enforces permissions.

Built on the Ethereum/ERC‑20/ERC‑721 standards, the toolkit supports:

•⁠  ⁠*Community Value Tokens* (community currency)  
•⁠  ⁠*Purpose‑Driven Tokens* (civic‑engagement rewards)  
•⁠  ⁠*Coupons* (vouchers & passes)  
•⁠  ⁠*Badges* (achievement NFTs)  
•⁠  ⁠*Membership SBTs* (soulbound membership)  
•⁠  ⁠*Physical‑Object NFTs* (borrowable assets)  
•⁠  ⁠*Event Tickets* (ticketing & collectibles)  

A central *Registry* contract tracks community roles (that can be instantiated for example by associations, citizens, retailers) and allows to enforce role based minting, burning and transfers.
RoleBased.sol ensures that each token relies to a valid Registry by enforcing ERC-165 compliance with the IRegistry.sol interface.
