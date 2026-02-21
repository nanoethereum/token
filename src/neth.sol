// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "solady-v0.1.26/src/tokens/ERC20.sol";

/**
 * @title nETH
 * @notice Wrapped ETH with 1 ETH = 1,000,000 nETH (6 decimal places offset)
 * @dev Minimal ETH wrapper inspired by WETH9, but with micro-scaling for higher precision
 *      1 ETH → 1_000_000 nETH (internally uses 18 decimals like standard ERC20)
 */
contract nETH is ERC20 {
    /// @notice Conversion rate: 1 ETH = 1e6 nETH
    uint256 public constant CONVERSION_RATE = 1e6;

    event Deposit(address indexed dst, uint256 ethAmount, uint256 nethAmount);
    event Withdrawal(address indexed src, uint256 ethAmount, uint256 nethAmount);

    error InsufficientBalance();
    error TransferFailed();
    error InvalidAmount();

    /**
     * @notice Token name
     */
    function name() public pure override returns (string memory) {
        return "Nano ETH";
    }

    /**
     * @notice Token symbol
     */
    function symbol() public pure override returns (string memory) {
        return "nETH";
    }

    /**
     * @notice Token decimals (standard 18)
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @notice Deposit ETH and mint nETH (1 ETH = 1e6 nETH)
     */
    function deposit() public payable {
        if (msg.value == 0) revert InvalidAmount();

        uint256 nethAmount = msg.value * CONVERSION_RATE;
        _mint(msg.sender, nethAmount);

        emit Deposit(msg.sender, msg.value, nethAmount);
    }

    /**
     * @notice Burn nETH and withdraw ETH
     * @param wad Amount of nETH to burn (must be multiple of CONVERSION_RATE to withdraw full wei)
     */
    function withdraw(uint256 wad) public {
        if (wad == 0) revert InvalidAmount();
        if (balanceOf(msg.sender) < wad) revert InsufficientBalance();

        uint256 ethAmount = wad / CONVERSION_RATE;
        if (ethAmount == 0) revert InvalidAmount();

        _burn(msg.sender, wad);

        // solady ERC20 uses safe math internally; low-level call for ETH transfer is standard
        (bool success, ) = msg.sender.call{value: ethAmount}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(msg.sender, ethAmount, wad);
    }

    /**
     * @notice Fallback: deposit ETH when sending ETH directly to contract
     */
    receive() external payable {
        deposit();
    }

    // ────────────────────────────────────────────────────────────────────────────────
    // Utility view functions for clarity
    // ────────────────────────────────────────────────────────────────────────────────

    /**
     * @notice Total ETH held by the contract (should ≈ totalSupply / CONVERSION_RATE)
     */
    function totalETH() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Convert ETH amount to nETH amount
     */
    function toNETH(uint256 ethAmount) public pure returns (uint256) {
        return ethAmount * CONVERSION_RATE;
    }

    /**
     * @notice Convert nETH amount to ETH amount (floors)
     */
    function toETH(uint256 nethAmount) public pure returns (uint256) {
        return nethAmount / CONVERSION_RATE;
    }

    /**
     * @notice Get user's nETH balance expressed in ETH (floored)
     */
    function ethBalanceOf(address account) public view returns (uint256) {
        return toETH(balanceOf(account));
    }
}