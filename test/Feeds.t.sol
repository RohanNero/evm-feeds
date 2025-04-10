// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Feeds} from "../src/Feeds.sol";

contract FeedsTest is Test {
    Feeds public feed;

    address private constant dead = 0x000000000000000000000000000000000000dEaD;

    function setUp() public {
        feed = new Feeds();
    }
    
    /**@notice Test updating the price using Chainlink's AggregatorV3. */
    function test_updateChainlink() public {
        vm.startPrank(dead);
        (int256 initialPrice, uint256 initialTimestamp) = feed.viewPrice();
        
        feed.update(0);

        (int256 price, uint256 timestamp) = feed.viewPrice();
        console.log("Price:", price);
        console.log("Timestamp:", timestamp);
        console.log("Age:", block.timestamp - timestamp);

        assertTrue(initialPrice != price, "Price not updated");
        assertTrue(initialTimestamp < timestamp, "Timestamp not updated");
        vm.stopPrank();
    }

    /**@notice Test updating the price using Uniswap V3's WETH/USDC pool. */
    function test_updateUniswapV3() public {
        vm.startPrank(dead);
        (int256 initialPrice, uint256 initialTimestamp) = feed.viewPrice();
        
        feed.update(1);

        (int256 price, uint256 timestamp) = feed.viewPrice();
        
        console.log("Price:", price);
        console.log("Timestamp:", timestamp);
        console.log("Age:", block.timestamp - timestamp);

        assertTrue(initialPrice != price, "Price not updated");
        assertTrue(initialTimestamp < timestamp, "Timestamp not updated");
        vm.stopPrank();
    }

    /**@notice Test updating the price using Pyth. 
     * @dev
    */
    function test_updatePyth() public {
        vm.startPrank(dead);
        (int256 initialPrice, uint256 initialTimestamp) = feed.viewPrice();
        
        feed.update(2);

        (int256 price, uint256 timestamp) = feed.viewPrice();
        console.log("Price:", price);
        console.log("Timestamp:", timestamp);
        console.log("Age:", block.timestamp - timestamp);

        assertTrue(initialPrice != price, "Price not updated");
        assertTrue(initialTimestamp < timestamp, "Timestamp not updated");
        vm.stopPrank();
    }

}
