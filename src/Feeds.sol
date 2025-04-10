// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

/** Chainlink 
 * https://github.com/smartcontractkit/chainlink/tree/develop
*/
import "./Chainlink/AggregatorV3Interface.sol";

/** Uniswap V3 
 * https://github.com/Uniswap/v3-core/tree/0.8
*/
import "./UniswapV3/IUniswapV3PoolState.sol";

/** Pyth 
 * https://github.com/pyth-network/pyth-crosschain/tree/main/target_chains/ethereum/sdk/solidity
*/
import "./Pyth/IPyth.sol";
import "./Pyth/PythStructs.sol";

/**
 * @title Feed
 * @author Rohan Nero
 * @notice This contract was created to showcase the various ways that prices can be retrieved on-chain.
 * @dev All pricefeeds are for ETH/USD.
 */
contract Feeds {

    /**@notice Used when attempting to update the price using a timestamp older than the one stored. */
    error Feed__InvalidTimestamp();

    /**@notice The latest ETH price with 8 decimals. */
    int256 private _latestETHPrice;
    /**@notice The latest price update in the form of a UNIX timestamp (seconds). */
    uint256 private _lastUpdatedTimestamp;

    /** Price feeds */
    address private constant _chainlinkFeed = 0x5147eA642CAEF7BD9c1265AadcA78f997AbB9649;
    address private constant _uniswapV3Feed = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
    address private constant _pythFeed = 0x4305FB66699C3B2702D4d05CF36551390A4c69C6;

    /**@notice Updates the latest price and timestamp. 
     * @dev The pricefeed used is determined by the user input.
     * @dev Ids: 0 = Chainlink, 1 = UniswapV3, 2 = Pyth
     * @param feedId The id of the pricefeed to use.
     */
    function update(uint8 feedId) public payable returns (int256 _price, uint256 _timestamp){
        if(feedId == 0) {
            (_price, _timestamp) = _useChainlink();
        } else if (feedId == 1) {
            (_price, _timestamp) = _useUniswapV3();
        } else if (feedId == 2) {
            (_price, _timestamp) = _usePyth();
        }
    }

    /**@notice Returns the latest price and timestamp. */
    function viewPrice() public view returns (int256, uint256) {
        return (_latestETHPrice, _lastUpdatedTimestamp);
    }

    /** Internal Functions */

    /**@notice Updates the feed and timestamp using Chainlink. 
     * @dev https://docs.chain.link/data-feeds/using-data-feeds#reading-data-feeds-onchain
    */
    function _useChainlink() internal returns (int256 _price, uint256 _timestamp) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_chainlinkFeed);
        (
            /* uint80 roundID */,
            int256 price,
            /* uint256 startedAt */,
            uint256 timestamp,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();

        _update(price, timestamp);
        return (price, timestamp);
    }

    /**@notice Using Uniswap V3's slot0() to retrieve the latest price. 
     * @dev https://docs.uniswap.org/contracts/v3/reference/core/interfaces/pool/IUniswapV3PoolState#slot0
     * @dev Not as secure as using observe() to compare multiple ticks and calculate a TWAP.
     * @dev https://docs.uniswap.org/concepts/protocol/oracle#deriving-price-from-a-tick
    */
    function _useUniswapV3() internal returns (int256 _price, uint256 _timestamp) {
        IUniswapV3PoolState pool = IUniswapV3PoolState(_uniswapV3Feed);
        (uint160 sqrtPriceX96, , uint16 index, , , ,) = pool.slot0();
        (uint32 timestamp,,,) = pool.observations(index);

        /** Price of 1 USDC in terms of WETH */
        uint256 flippedPrice = (sqrtPriceX96 >> 96) ** 2;   
        /** Calculate the inverse price in terms of ETH/USD as opposed to USD/ETH */
        /** We use 1e20 since the price currently has 12 decimals (8 decimals remain to match the shared format) */
        uint price = (1e20 / (flippedPrice));

        _update(int256(price), uint256(timestamp));
        return (int256(price), uint256(timestamp));
    }

    /**@notice Updates the feed and timestamp using Pyth. 
     * @dev Uses `getPriceUnsafe()` to get the latest published price.
     * @dev Doesn't follow the documented update process to update the pricefeed with `updatePriceFeeds()`,
     * and subsequently call `getPriceNoOlderThan()`.
     * @dev https://docs.pyth.network/price-feeds/use-real-time-data/evm
    */
    function _usePyth() internal returns (int256 _price, uint256 _timestamp) {
        // Each price feed (e.g., ETH/USD) is identified by a price feed ID.
        // The complete list of feed IDs is available at https://pyth.network/developers/price-feed-ids
        bytes32 priceFeedId = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace; // ETH/USD
        PythStructs.Price memory price = IPyth(_pythFeed).getPriceUnsafe(priceFeedId);

        _update(int256(price.price), price.publishTime);
        return (int256(price.price), price.publishTime);
    }

    /**@notice Updates the timestamp and price variables.
     * @dev The new timestamp must be greater than the previous timestamp.
     */
    function _update(int256 price, uint256 timestamp) internal {
        require(timestamp > _lastUpdatedTimestamp, Feed__InvalidTimestamp());
        _latestETHPrice = price;
        _lastUpdatedTimestamp = timestamp;
    } 
}
