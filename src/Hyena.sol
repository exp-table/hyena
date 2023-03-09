// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Hyena {

    /// Initializes and returns a new payload.
    ///
    /// # Example
    ///
    /// ```
    /// bytes memory payload = Hyena.init();
    /// ```
    function init() internal pure returns (bytes memory payload) {
        assembly {
            payload := mload(0x40)
            mstore(payload, 0x40) // add the map and an empty slot
            mstore(0x40, add(payload, 0x520)) // update free mem ptr
        }
        return payload;
    }

    /// Adds a new uint256 prey (value) to the payload and returns the updated payload.
    ///
    /// # Arguments
    ///
    /// * `payload` - The payload to add the prey to.
    /// * `prey` - The prey to add to the payload.
    ///
    /// # Example
    ///
    /// ```
    /// bytes memory payload = Hyena.init();
    /// payload = Hyena.crush(payload, uint(100));
    /// payload = Hyena.crush(payload, uint(2**256 - 1));
    /// ```
    function crush(bytes memory payload, uint256 prey) internal pure returns (bytes memory) {
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
            let map := mload(add(payload, 0x20))
            let mass := add(div(sub(255, clz(prey)), 8), 1)
            // move to big endian
            prey := shl(sub(256, shl(3, mass)), prey)
            // | 16 bits    |        6 bits          | .... |
            // | bytes used | length of last element | .... |
            // get last 6 bits, if they are set => we full
            if eq(and(shr(234, map), 0x2ff), 0) {
                // no more space left, move onto next chunk
                if gt(mass, sub(sub(mload(payload), 0x20), shr(246, map))) {
                    mstore(0x40, add(mload(0x40), 0x20)) // update free mem ptr
                    mstore(payload, add(mload(payload), 0x20)) // update bytes length
                }
                // store prey
                mstore(add(add(payload, 0x40), shr(246, map)), prey)
                // make space and set the mass (length) of the newly added prey
                let new_map := or(shl(6, map), mass)
                new_map := or(and(new_map, 0x003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF), add(and(map, 0xFFC0000000000000000000000000000000000000000000000000000000000000), shl(246, mass)))
                // update map
                mstore(add(payload, 0x20), new_map)
            }
        }
        return payload;
    }

    /// Unpack the payload into an array of uint256s.
    /// The maximum size possible is 40.
    /// BEWARE ; the elements are returned in the reverse order they were added.
    ///
    /// # Arguments
    ///
    /// * `payload` - The payload to digest.
    ///
    /// # Example
    ///
    /// ```
    /// bytes memory payload = Hyena.init();
    /// payload = Hyena.crush(payload, uint(100));
    /// payload = Hyena.crush(payload, uint(2**256 - 1));
    /// uint256[] memory outputs = Hyena.digest(payload);
    /// assert(outputs[0] == 2**256 - 1);
    /// ```
    function digest(bytes memory payload) internal pure returns (uint256[] memory outputs) {
        assembly {
            let map := and(mload(add(payload, 0x20)), 0x003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            let total_size := shr(246, mload(add(payload, 0x20)))
            outputs := mload(0x40)
            mstore(0x40, add(outputs, 0x520)) // make space for 40 elements
            let ptr := add(outputs, 0x20) // where to store next value
            for {} gt(total_size, 0) {} {
                // get the first 6 bits = length of last element
                let lsize := and(map, 0x3f)
                // get the last element, shift it to the right
                mstore(ptr, shr(sub(256, shl(3, lsize)), mload(add(add(payload, 0x40), sub(total_size, lsize)))))
                // update map
                map := shr(6, map)
                total_size := sub(total_size, lsize)
                ptr := add(ptr, 0x20)
                mstore(outputs, add(mload(outputs), 0x20)) // update outputs's length
            }
        }
    }

    /// Returns the total size (excluding the map) of the payload.
    ///
    /// # Arguments
    ///
    /// * `payload` - The payload to get the size of
    ///
    /// # Example
    ///
    /// ```
    /// bytes memory payload = Hyena.init();
    /// payload = Hyena.crush(payload, uint(100));
    /// payload = Hyena.crush(payload, uint(2**256 - 1));
    /// uint256 length = Hyena.size(payload);
    /// ```
    function size(bytes memory payload) internal pure returns (uint256 mass) {
        assembly {
            mass := shr(246, mload(add(payload, 0x20)))
        }
    }
}
