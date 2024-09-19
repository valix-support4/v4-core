// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Currency} from "../../src/types/Currency.sol";
import {IERC20Minimal} from "../../src/interfaces/external/IERC20Minimal.sol";
import {IPoolManager} from "../../src/interfaces/IPoolManager.sol";

/// @notice Library used to interact with PoolManager.sol to settle any open deltas.
/// To settle a positive delta (a credit to the user), a user may take or mint.
/// To settle a negative delta (a debt on the user), a user make transfer or burn to pay off a debt.
/// @dev Note that sync() is called before any erc-20 transfer in `settle`.
library CurrencySettler {
    /// @notice Settle (pay) a currency to the PoolManager
    /// @param currency Currency to settle
    /// @param manager IPoolManager to settle to
    /// @param payer Address of the payer, the token sender
    /// @param amount Amount to send
    /// @param burn If true, burn the ERC-6909 token, otherwise ERC20-transfer to the PoolManager
    function settle(Currency currency, IPoolManager manager, address payer, uint256 amount, bool burn) internal {
        // case 1
        // เรียกมาจาก DeltaReturningHook._settleOrTake
        // โดย manager = address poolManager
        // payer = address ของ hook
        // amount = hookDeltaSpecified = -1e6
        // burn = false

        // for native currencies or burns, calling sync is not required
        // short circuit for ERC-6909 burns to support ERC-6909-wrapped native tokens
        if (burn) {
            // case 1
            // if (false)
            manager.burn(payer, currency.toId(), amount);
        } else if (currency.isAddressZero()) {
            // case 1
            // if(token 0 address == 0x00)
            // if(false)
            manager.settle{value: amount}();
        } else {
            // case 1
            // ไปเรียก poolManager.sync โดยส่ง currency = address ของ token0
            manager.sync(currency);
            // case 1
            // การ sync เป็นการ save ค่า token0.balanceOf(poolManager) เป็น snapshot ไว้
            if (payer != address(this)) {
                // case 1 
                // เป็น false
                IERC20Minimal(Currency.unwrap(currency)).transferFrom(payer, address(manager), amount);
            } else {
                // case 1 
                // เข้า else
                IERC20Minimal(Currency.unwrap(currency)).transfer(address(manager), amount);
            }
            // case 1
            // ทำการเรียก PoolManager.settle
            manager.settle();
            // เก็บค่า 1e6 ใน storage slot key (address ของ hook, token0) ของ PoolManager
        }
    }

    /// @notice Take (receive) a currency from the PoolManager
    /// @param currency Currency to take
    /// @param manager IPoolManager to take from
    /// @param recipient Address of the recipient, the token receiver
    /// @param amount Amount to receive
    /// @param claims If true, mint the ERC-6909 token, otherwise ERC20-transfer from the PoolManager to recipient
    function take(Currency currency, IPoolManager manager, address recipient, uint256 amount, bool claims) internal {
        claims ? manager.mint(recipient, currency.toId(), amount) : manager.take(currency, recipient, amount);
    }
}
