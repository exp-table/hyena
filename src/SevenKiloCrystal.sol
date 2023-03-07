// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SevenKiloCrystal {

    /// Cook and returns a new crystal (bytes).
    ///
    /// # Example
    ///
    /// ```
    /// bytes memory crystal = SevenKiloCrystal.cook();
    /// ```
    function cook() internal pure returns (bytes memory crystal) {
        assembly {
            crystal := mload(0x40)
            mstore(crystal, 0x40) // add the map and an empty slot
            mstore(0x40, add(crystal, 0x520)) // update free mem ptr
        }
        return crystal;
    }

    /// Adds a new uint256 compound (value) to the crystal and returns the updated crystal.
    ///
    /// # Arguments
    ///
    /// * `crystal` - The crystal to add the compound to.
    /// * `compound` - The compound to add to the crystal.
    ///
    /// # Example
    ///
    /// ```
    /// bytes memory crystal = SevenKiloCrystal.cook();
    /// crystal = SevenKiloCrystal.addition(crystal, uint(100));
    /// crystal = SevenKiloCrystal.addition(crystal, uint(2**256 - 1));
    /// ```
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
            compound := shl(sub(256, shl(3, mass)), compound)
            // | 16 bits    |        6 bits          | .... |
            // | bytes used | length of last element | .... |
            // get last 6 bits, if they are set => we full
            if eq(and(shr(234, map), 0x2ff), 0) {
                // no more space left, move onto next chunk
                if gt(mass, sub(sub(mload(crystal), 0x20), shr(246, map))) {
                    mstore(0x40, add(mload(0x40), 0x20)) // update free mem ptr
                    mstore(crystal, add(mload(crystal), 0x20)) // update bytes length
                }
                // store compound
                mstore(add(add(crystal, 0x40), shr(246, map)), compound)
                // make space and set the mass (length) of the newly added compound
                let new_map := or(shl(6, map), mass)
                new_map := or(and(new_map, 0x003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF), add(and(map, 0xFFC0000000000000000000000000000000000000000000000000000000000000), shl(246, mass)))
                // update map
                mstore(add(crystal, 0x20), new_map)
            }
        }
        return crystal;
    }

    /// Smoke (unpack) the crystal into an array of uint256s.
    /// The maximum size possible is 40.
    /// BEWARE ; the elements are returned in the reverse order they were added.
    ///
    /// # Arguments
    ///
    /// * `crystal` - The crystal to smoke.
    ///
    /// # Example
    ///
    /// ```
    /// bytes memory crystal = SevenKiloCrystal.cook();
    /// crystal = SevenKiloCrystal.addition(crystal, uint(100));
    /// crystal = SevenKiloCrystal.addition(crystal, uint(2**256 - 1));
    /// uint256[] memory smoked = SevenKiloCrystal.smoke(crystal);
    /// assert(smoked[0] == 2**256 - 1);
    /// ```
    function smoke(bytes memory crystal) internal pure returns (uint256[] memory smoked) {
        assembly {
            let map := and(mload(add(crystal, 0x20)), 0x003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            let total_mass := shr(246, mload(add(crystal, 0x20)))
            smoked := mload(0x40)
            mstore(0x40, add(smoked, 0x520)) // make space for 40 elements
            let ptr := add(smoked, 0x20) // where to store next value
            for {} gt(total_mass, 0) {} {
                // get the first 6 bits = length of last element
                let len := and(map, 0x3f)
                // get the last element, shift it to the right
                mstore(ptr, shr(sub(256, shl(3, len)), mload(add(add(crystal, 0x40), sub(total_mass, len)))))
                // update map
                map := shr(6, map)
                total_mass := sub(total_mass, len)
                ptr := add(ptr, 0x20)
                mstore(smoked, add(mload(smoked), 0x20)) // update smoked's length
            }
        }
    }

    /// Returns the molar mass (size in bytes of the compounds) of the crystal.
    ///
    /// # Arguments
    ///
    /// * `crystal` - The crystal to get the molar mass of.
    ///
    /// # Example
    ///
    /// ```
    /// bytes memory crystal = SevenKiloCrystal.cook();
    /// crystal = SevenKiloCrystal.addition(crystal, uint(100));
    /// crystal = SevenKiloCrystal.addition(crystal, uint(2**256 - 1));
    /// uint256 length = SevenKiloCrystal.molarMass(crystal);
    /// ```
    function molarMass(bytes memory crystal) internal pure returns (uint256 mass) {
        assembly {
            mass := shr(246, mload(add(crystal, 0x20)))
        }
    }
}
