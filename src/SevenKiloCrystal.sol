// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SevenKiloCrystal {

    function cook() internal pure returns (bytes memory kilo) {
        assembly {
            mstore(kilo, 0x40) // add the map and an empty slot
            mstore(0x40, add(mload(0x40), 0x20)) // update free mem ptr
        }
    }

    function addition(bytes memory crystal, uint256 compound) internal pure returns (bytes memory) {
        assembly {
            // from vectorized/solady
            function clz(x) -> r {
                let t := add(iszero(x), 255)
                r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
                r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
                r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
                x := shr(r, x)
                x := or(x, shr(1, x))
                x := or(x, shr(2, x))
                x := or(x, shr(4, x))
                x := or(x, shr(8, x))
                x := or(x, shr(16, x))
                // forgefmt: disable-next-item
                r := sub(t, or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))),
                    0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f)))
            }
            let map := mload(add(crystal, 0x20))
            let mass := add(div(sub(255, clz(compound)), 8), 1)
            // move to big endian
            compound := shl(clz(compound), compound)
            // | 16 bits    |        6 bits          | .... |
            // | bytes used | length of last element | .... |
            if gt(and(shr(234, map), 0x2ff), 0) {
                // WRONG
                return(crystal, add(crystal, mload(crystal)))
            }
            // mem expansion needed if compound's size greater than the chunk left
            // TODO : recopy entire crystal to new memory if memory collision
            if gt(mass, sub(sub(mload(crystal), 0x20), shr(246, map))) {
                // for { let i } lt(i, 0x100) { i := add(i, 0x20) } {
                //     x := add(x, mload(i))
                // }
                let nwptr := add(mload(crystal), 0x20)
                mstore(0x40, add(mload(0x40), nwptr))
                mstore(crystal, nwptr)
            }
            // store compound
            mstore(add(add(crystal, 0x40), shr(246, map)), compound)
            // make space and set the mass (length) of the newly added compound
            let new_map := or(shl(6, map), mass)
            new_map := or(and(new_map, 0x003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF), add(and(map, 0xFFC0000000000000000000000000000000000000000000000000000000000000), shl(246, mass)))
            // update map
            mstore(add(crystal, 0x20), new_map)
        }
        return crystal;
    }

    function smoke(bytes memory crystal) internal pure returns (uint256[40] memory smoked) {

    }

    function molarMass(bytes memory crystal) internal pure returns (uint256 mass) {
        assembly {
            mass := shr(246, mload(add(crystal, 0x20)))
        }
    }
}
