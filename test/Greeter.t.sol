// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {SevenKiloCrystal as SKC} from "src/SevenKiloCrystal.sol";

contract SevenKiloCrystalTest is Test {

    function test() external {
        bytes memory payload = SevenKiloCrystal.cook();
        payload = cram(payload, uint(100));
        payload = SKC.cram(payload, uint(2**256 - 1));
        payload = SKC.cram(payload, uint(100));
        console.logBytes(payload);
    }
}
