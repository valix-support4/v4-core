// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Hooks} from "../../libraries/Hooks.sol";
import {IHooks} from "../../interfaces/IHooks.sol";
import {IPoolManager} from "../../interfaces/IPoolManager.sol";
import {CurrencySettler} from "../../../test/utils/CurrencySettler.sol";
import {PoolKey} from "../../types/PoolKey.sol";
import {BalanceDelta} from "../../types/BalanceDelta.sol";
import {Currency} from "../../types/Currency.sol";
import {BaseTestHooks} from "../BaseTestHooks.sol";
import {Currency} from "../../types/Currency.sol";
import {BeforeSwapDelta, toBeforeSwapDelta} from "../../types/BeforeSwapDelta.sol";
import {console} from "forge-std/console.sol";
contract HookAddTenPercentToTokenZero is BaseTestHooks {
    using Hooks for IHooks;
    using CurrencySettler for Currency;

    IPoolManager immutable manager;

    int128 deltaSpecified;
    int128 deltaUnspecifiedBeforeSwap;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    modifier onlyPoolManager() {
        require(msg.sender == address(manager));
        _;
    }

    function beforeSwap(
        address, /* sender **/
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata /* hookData **/
    ) external override onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24) {
        // case 1
        // ถูกเรียกมาจาก lib Hooks.callHook ใน PoolManager

        (Currency specifiedCurrency, Currency unspecifiedCurrency) = _sortCurrencies(key, params);
        // case 1
        // ได้ specifiedCurrency = token 0
        // unspecifiedCurrency = token 1
        // เพราะเป็น exactIn และ zeroForOne
        // ดังนั้นฝั่งที่ถูก fix ค่า / specify ค่ามา คือ token 0

        // case 1 
        // ได้ว่า
        // specifiedCurrency = token 0
        // deltaSpecified = -1e6
        if (params.amountSpecified < 0 && params.zeroForOne) {
            console.log("params.amountSpecified");
            console.logInt(params.amountSpecified);
            deltaSpecified = int128(params.amountSpecified) / 10;
            console.log("deltaSpecified");
            console.logInt(deltaSpecified);
            _settleOrTake(specifiedCurrency, deltaSpecified);
        }
        
        BeforeSwapDelta beforeSwapDelta = toBeforeSwapDelta(deltaSpecified, deltaUnspecifiedBeforeSwap);
        //ตรงนี้ pack ค่าเฉยๆ
        return (IHooks.beforeSwap.selector, beforeSwapDelta, 0);
    }

    function _sortCurrencies(PoolKey calldata key, IPoolManager.SwapParams calldata params)
        internal
        pure
        returns (Currency specified, Currency unspecified)
    {
        (specified, unspecified) = (params.zeroForOne == (params.amountSpecified < 0))
            ? (key.currency0, key.currency1)
            : (key.currency1, key.currency0);
    }

    function _settleOrTake(Currency currency, int128 delta) internal {
        if(delta < 0) {
            uint256 amount = uint256(-int256(delta));
            currency.settle(manager, address(this), amount, false);
        }
    }
}
