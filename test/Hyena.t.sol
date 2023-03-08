// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Hyena} from "src/Hyena.sol";

contract HyenaTest is Test {

    function test() external {
        bytes memory payload = Hyena.init();
        payload = Hyena.crush(payload, uint(100));
        payload = Hyena.crush(payload, uint(2**256 - 1));
        payload = Hyena.crush(payload, uint(100));
        payload = Hyena.crush(payload, uint(2**16));
        payload = Hyena.crush(payload, uint(2**32));
        payload = Hyena.crush(payload, uint(2**64));

        assertEq(Hyena.size(payload), 1+32+1+3+5+9);

        uint[] memory yummy = Hyena.digest(payload);
        assertEq(yummy[0], 2**64);
        assertEq(yummy[1], 2**32);
        assertEq(yummy[2], 2**16);
        assertEq(yummy[3], 100);
        assertEq(yummy[4], 2**256 - 1);
        assertEq(yummy[5], 100);
    }
}
