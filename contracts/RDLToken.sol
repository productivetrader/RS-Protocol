// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract RDLToken is ERC20PresetMinterPauser, ERC20Capped {
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        address admin
    ) ERC20PresetMinterPauser(name, symbol) ERC20Capped(maxSupply * 1 ether) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        if(admin != msg.sender) {
            _revokeRole(PAUSER_ROLE, msg.sender);
            _revokeRole(MINTER_ROLE, msg.sender);
            _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        }
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);
    }
} 