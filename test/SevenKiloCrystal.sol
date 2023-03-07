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
        payload = SKC.addition(payload, uint(2**16));
        payload = SKC.addition(payload, uint(2**32));
        payload = SKC.addition(payload, uint(2**64));

        assertEq(SKC.molarMass(payload), 1+32+1+3+5+9);

        uint[] memory yummy = SKC.smoke(payload);
        assertEq(yummy[0], 2**64);
        assertEq(yummy[1], 2**32);
        assertEq(yummy[2], 2**16);
        assertEq(yummy[3], 100);
        assertEq(yummy[4], 2**256 - 1);
        assertEq(yummy[5], 100);
    }
}
