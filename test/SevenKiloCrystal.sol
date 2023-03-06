// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {SevenKiloCrystal as SKC} from "src/SevenKiloCrystal.sol";

contract SevenKiloCrystalTest is Test {

    function test() external {
        bytes memory payload = SKC.cook();
        payload = SKC.addition(payload, uint(100));
        payload = SKC.addition(payload, uint(2**256 - 1));
        payload = SKC.addition(payload, uint(100));
        console.logBytes(payload);
        //payload = SKC.addition(payload, uint(100));
    }
}
