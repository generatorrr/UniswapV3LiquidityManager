pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/UniswapV3LiquidityManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV3LiquidityManagerTest is Test {
    UniswapV3LiquidityManager liquidityManager;

    address positionManagerAddress = vm.addr(1);
    address poolAddress = vm.addr(2);

    function setUp() public {
        liquidityManager = new UniswapV3LiquidityManager(positionManagerAddress);
    }

    function testAddLiquidity() public {

        uint256 amount0 = 1000 * 10**18;
        uint256 amount1 = 2000 * 10**6;
        uint256 width = 500;

        IERC20(IUniswapV3Pool(poolAddress).token0()).approve(address(liquidityManager), amount0);
        IERC20(IUniswapV3Pool(poolAddress).token1()).approve(address(liquidityManager), amount1);

        uint256 tokenId = liquidityManager.addLiquidity(poolAddress, amount0, amount1, width);

        assertGt(tokenId, 0, "Token ID should be greater than 0");
    }

    function testGetCurrentPrice() public {

        uint256 price = liquidityManager.getCurrentPrice(poolAddress);

        assertGt(price, 0, "Current price should be greater than 0");
    }

    function testGetTick() public {

        uint256 price = 1000 * 10**18; // Example price of 1000
        int24 tick = liquidityManager.testGetTick(price);

        assertGe(tick, -887272, "Tick should be in range");
        assertLe(tick, 887272, "Tick should be in range");
    }

    function testFailAddLiquidityWithInvalidTicks() public {
        uint256 amount0 = 1000 * 10**18;
        uint256 amount1 = 2000 * 10**6;
        uint256 width = 10000;

        IERC20(IUniswapV3Pool(poolAddress).token0()).approve(address(liquidityManager), amount0);
        IERC20(IUniswapV3Pool(poolAddress).token1()).approve(address(liquidityManager), amount1);

        vm.expectRevert("Ticks out of bounds");
        liquidityManager.addLiquidity(poolAddress, amount0, amount1, width);
    }
}
