// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import {Currency} from "../types/Currency.sol";
import {CustomRevert} from "./CustomRevert.sol";

library CurrencyReserves {
    using CustomRevert for bytes4;

    /// bytes32(uint256(keccak256("ReservesOf")) - 1)
    bytes32 constant RESERVES_OF_SLOT = 0x1e0745a7db1623981f0b2a5d4232364c00787266eb75ad546f190e6cebe9bd95;
    /// bytes32(uint256(keccak256("Currency")) - 1)
    bytes32 constant CURRENCY_SLOT = 0x27e098c505d44ec3574004bca052aabf76bd35004c182099d8c575fb238593b9;

    function getSyncedCurrency() internal view returns (Currency currency) {
        assembly ("memory-safe") {
            currency := tload(CURRENCY_SLOT)
        }
    }

    function resetCurrency() internal {
        // case 1
        // เรียกมาจาก DeltaReturningHook.beforeSwap => ... => PoolManager._settle()
        // เป็นการเคลียร์ค่า address 0 ที่เก็บไว้ออก
        assembly ("memory-safe") {
            tstore(CURRENCY_SLOT, 0)
        }
    }

    function syncCurrencyAndReserves(Currency currency, uint256 value) internal {
        // case 1
        // เรียกมาจาก PoolManager.sync
        // โดย currency = token 0
        // balance = token0.balanceOf(poolManager)

        // จาก code, case 1 จะมีการทำงานส่วนนี้คือ
        // CURRENCY_SLOT คือ bytes32(uint256(keccak256("Currency")) - 1)
        // tstore(CURRENCY_SLOT, and(currency, 0xffffffffffffffffffffffffffffffffffffffff))
        // คือการ save ค่าของ (address token 0 & 0xff) ไว้ที่ slot CURRENCY_SLOT
        // RESERVES_OF_SLOT คือ bytes32(uint256(keccak256("ReservesOf")) - 1)
        // tstore(RESERVES_OF_SLOT, value) 
        // คือการ save ค่า token0.balanceOf(poolManager) ไว้ที่ slot RESERVES_OF_SLOT
        assembly ("memory-safe") {
            tstore(CURRENCY_SLOT, and(currency, 0xffffffffffffffffffffffffffffffffffffffff))
            tstore(RESERVES_OF_SLOT, value)
        }
    }

    function getSyncedReserves() internal view returns (uint256 value) {
        assembly ("memory-safe") {
            value := tload(RESERVES_OF_SLOT)
        }
    }
}
