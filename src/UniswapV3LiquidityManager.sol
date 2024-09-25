pragma solidity ^0.8.10;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV3LiquidityManager {
    INonfungiblePositionManager public positionManager;

    constructor(address positionManagerAddress) {
        positionManager = INonfungiblePositionManager(positionManagerAddress);
    }

    function addLiquidity(
        address poolAddress,
        uint256 amount0,
        uint256 amount1,
        uint256 width
    ) external returns (uint256 tokenId) {

        uint256 currentPrice = getCurrentPrice(poolAddress);

        uint256 lowerPrice = currentPrice * (10000 - width) / 10000;
        uint256 upperPrice = currentPrice * (10000 + width) / 10000;

        int24 lowerTick = getTick(lowerPrice);
        int24 upperTick = getTick(upperPrice);

        require(lowerTick >= -887272 && upperTick <= 887272, "Ticks out of bounds");

        IERC20(IUniswapV3Pool(poolAddress).token0()).transferFrom(msg.sender, address(this), amount0);
        IERC20(IUniswapV3Pool(poolAddress).token1()).transferFrom(msg.sender, address(this), amount1);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: IUniswapV3Pool(poolAddress).token0(),
            token1: IUniswapV3Pool(poolAddress).token1(),
            fee: IUniswapV3Pool(poolAddress).fee(),
            tickLower: lowerTick,
            tickUpper: upperTick,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: msg.sender,
            deadline: block.timestamp + 15 minutes
        });

        (tokenId, , , ) = positionManager.mint(params);
        return tokenId;
    }

    function getTick(uint256 price) internal pure returns (int24) {

        uint256 logPrice = log2(price);
        require(logPrice <= 2**24 - 1, "log2 result out of bounds");
        int24 tick = int24(int256(logPrice));
        require(tick >= -887272 && tick <= 887272, "Tick out of bounds");
        return tick;
    }

    function log2(uint256 x) internal pure returns (uint256) {

        require(x > 0, "log2: x must be greater than 0");
        uint256 result = 0;
        while (x > 1) {
            x /= 2;
            result++;
        }
        return result;
    }

    function getCurrentPrice(address poolAddress) public view returns (uint256) {

        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(poolAddress).slot0();
        return uint256(sqrtPriceX96) ** 2 / 2**192;
    }

    function testGetTick(uint256 price) external pure returns (int24) {
        return getTick(price);
    }
}
