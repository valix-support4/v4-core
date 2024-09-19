// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import {Currency} from "../types/Currency.sol";
import {console} from "forge-std/console.sol";
/// @title a library to store callers' currency deltas in transient storage
/// @dev this library implements the equivalent of a mapping, as transient storage can only be accessed in assembly
library CurrencyDelta {
    /// @notice calculates which storage slot a delta should be stored in for a given account and currency
    function _computeSlot(address target, Currency currency) internal pure returns (bytes32 hashSlot) {
        assembly ("memory-safe") {
            mstore(0, and(target, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(32, and(currency, 0xffffffffffffffffffffffffffffffffffffffff))
            hashSlot := keccak256(0, 64)
        }
    }

    function getDelta(Currency currency, address target) internal view returns (int256 delta) {
        bytes32 hashSlot = _computeSlot(target, currency);
        assembly ("memory-safe") {
            delta := tload(hashSlot)
        }
    }

    /// @notice applies a new currency delta for a given account and currency
    /// @return previous The prior value
    /// @return next The modified result
    function applyDelta(Currency currency, address target, int128 delta)
        internal
        returns (int256 previous, int256 next)
    {
        // case 1
        // เรียกมาจาก
        // hook.beforeSwap => ... => PoolManager._accountDelta
        // currency = address 0
        // delta = เงินที่ hook จ่ายเข้ามาที่ poolManager = 1e6
        // target = address ของ hook
        bytes32 hashSlot = _computeSlot(target, currency);
        // case 1
        // หา storage slot สำหรับ key (address ของ hook, token0)
        assembly ("memory-safe") {
            previous := tload(hashSlot)
        }
        // case 1 จะได้ previous = 0
        console.log("previous ");
        console.logInt(previous);
        next = previous + delta;
        // case 1 จะได้ next = delta = เงินที่ hook จ่ายเข้ามาที่ poolManager = 1e6
        assembly ("memory-safe") {
            tstore(hashSlot, next)
        }
        // case 1 จะเก็บค่า 1e6 ใน storage slot key (address ของ hook, token0)
    }
}
