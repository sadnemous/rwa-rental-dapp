// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract RWA1155 is ERC1155 {

    IERC20 public usdc;

    mapping(uint256 => uint256) public totalShares;
    mapping(uint256 => uint256) public rentPool;
    mapping(uint256 => mapping(address => uint256)) public claimed;

    constructor(address _usdc) ERC1155("") {
        usdc = IERC20(_usdc);
    }

    function mintProperty(uint256 id, uint256 shares) external {
        _mint(msg.sender, id, shares, "");
        totalShares[id] = shares;
    }

    function payRent(uint256 id, uint256 amount) external {
        require(usdc.transferFrom(msg.sender, address(this), amount), "transfer failed");
        rentPool[id] += amount;
    }

    function claimRent(uint256 id) external {
        uint256 holderShares = balanceOf(msg.sender, id);
        require(holderShares > 0, "no shares");

        uint256 total = totalShares[id];
        uint256 entitled = (rentPool[id] * holderShares) / total;
        uint256 already = claimed[id][msg.sender];

        uint256 payableAmount = entitled - already;
        require(payableAmount > 0, "nothing to claim");

        claimed[id][msg.sender] = entitled;
        usdc.transfer(msg.sender, payableAmount);
    }
}
