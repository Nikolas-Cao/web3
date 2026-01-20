// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyERC20 is ERC20, ERC20Permit, ERC20Pausable, ERC20Votes, Ownable {
    mapping(address => bool) private _blacklist;

    event BlackListUpdate(address indexed user, bool value);

    constructor(string memory name, string memory symbol, uint initialSupply)
        ERC20(name, symbol)
        Ownable(msg.sender)
        ERC20Permit(name)
    {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
    
    /*
        admin functions
    */
    function updateBlacklist(address user, bool value) external onlyOwner {
        _blacklist[user] = value;
        emit BlackListUpdate(user, value);
    }

    function isInBlackList(address user) external view returns (bool) {
        return _blacklist[user];
    }

    function pause() external onlyOwner() {
        _pause();
    }

    function unpause() external onlyOwner() {
        _unpause();
    }

    /* 
        core override
     */
    function _update(address from, address to, uint256 value) internal 
    override(ERC20, ERC20Pausable, ERC20Votes) whenNotPaused {
        require(!_blacklist[from], "sender is in blacklist");
        require(!_blacklist[to], "to is in blacklist");
        ERC20._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces)
    returns (uint256)
    {
        return super.nonces(owner);
    }
}