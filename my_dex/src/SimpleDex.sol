// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract SimpleDex {

    error SimpleDex__InsufficientShares(uint256 shares);

    IERC20 public token0;
    IERC20 public token1;

    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function _mint(address to, uint256 amount) private {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function _burn(address from, uint256 amount) private {
        balanceOf[from] -= amount;
        totalSupply -= amount;
    }

    function addLiquidity(uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min) external returns(uint256 shares) {
        uint256 amount0;
        uint256 amount1;
        // 0. make sure that meet the minimal 
        if (totalSupply == 0) {
            (amount0, amount1) = (amount0Desired, amount1Desired);
        } else {
            uint256 amount1Optimal = (amount0Desired * reserve1) / reserve0;
            if (amount1Optimal <= amount1Desired) {
                require(amount1Optimal >= amount1Min, "insufficient 1 amount");
                (amount0, amount1) = (amount0Desired, amount1Optimal);
            } else {
                uint256 amount0Optimal = (amount1Desired * reserve0) / reserve1;
                require(amount0Optimal >= amount0Min, "insufficient 0 amount");
                (amount0, amount1) = (amount0Optimal, amount1Desired);
            }
        }

        // 1. caculate the shares
        if (totalSupply == 0) {
            shares = _sqrt(amount0 * amount1);
        } else {
            shares = _min(
                (amount0 * totalSupply) / reserve0,
                (amount1 * totalSupply) / reserve1
            );
        }
        
        // 2. transfer from msg.sender to this contract
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        require(shares > 0, "shares must be > 0");
        _mint(msg.sender, shares);
        _updateReserves();
    }

    function swap(address tokenIn, uint256 amountIn, uint256 amountOutMin) external returns(uint256 amountOut) {
        require(tokenIn == address(token0) || tokenIn == address(token1), "Invalid token address");
        bool isToken0 = tokenIn == address(token0);
        (IERC20 tIn, IERC20 tOut, uint256 rIn, uint256 rOut) = isToken0 ?
        (token0, token1, reserve0, reserve1) : (token1, token0, reserve1, reserve0);

        tIn.transferFrom(msg.sender, address(this), amountIn);

        // (rInt + amountIn) * (rOut - amountOut) = rIn * rOut
        uint256 amountInWithFee = (amountIn * 997) / 1000;
        amountOut = (rOut * amountInWithFee) / (rIn + amountInWithFee);

        require(amountOut >= amountOutMin, "slippage too hight : acutal out < min out");

        tOut.transfer(msg.sender, amountOut);
        _updateReserves();
    }

    function removeLiquidity(uint256 shares) external returns (uint256 amount0, uint256 amount1) {
        if (balanceOf[msg.sender] < shares) {
            revert SimpleDex__InsufficientShares(balanceOf[msg.sender]);
        }
        amount0 = (shares * reserve0) / totalSupply;
        amount1 = (shares * reserve1) / totalSupply;

        _burn(msg.sender, shares);
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        _updateReserves();
    }

    function _updateReserves() private {
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));
    }

    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}