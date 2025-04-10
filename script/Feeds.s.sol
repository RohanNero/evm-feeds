// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Feeds} from "../src/Feeds.sol";

contract FeedScript is Script {
    Feeds public feed;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        feed = new Feeds();

        vm.stopBroadcast();
    }
}
