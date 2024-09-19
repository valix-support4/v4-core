// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Hooks} from "../libraries/Hooks.sol";
import {IHooks} from "../interfaces/IHooks.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {CurrencySettler} from "../../test/utils/CurrencySettler.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {Currency} from "../types/Currency.sol";
import {BaseTestHooks} from "./BaseTestHooks.sol";
import {Currency} from "../types/Currency.sol";
import {BeforeSwapDelta, toBeforeSwapDelta} from "../types/BeforeSwapDelta.sol";

contract DeltaReturningHook is BaseTestHooks {
    using Hooks for IHooks;
    using CurrencySettler for Currency;

    IPoolManager immutable manager;

    int128 deltaSpecified;
    int128 deltaUnspecifiedBeforeSwap;
    int128 deltaUnspecifiedAfterSwap;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    modifier onlyPoolManager() {
        require(msg.sender == address(manager));
        _;
    }

    function setDeltaSpecified(int128 delta) external {
        deltaSpecified = delta;
    }

    function setDeltaUnspecifiedBeforeSwap(int128 delta) external {
        deltaUnspecifiedBeforeSwap = delta;
    }

    function setDeltaUnspecifiedAfterSwap(int128 delta) external {
        deltaUnspecifiedAfterSwap = delta;
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
        if (deltaSpecified != 0) _settleOrTake(specifiedCurrency, deltaSpecified);
        //สิ่งที่เกิดขึ้นคือ โอน token0 จำนวน 1e6 จาก hook ให้ poolManager และ ทาง poolManager ก็จะไว้แล้วว่า hook โอนมาเท่านั้น
        if (deltaUnspecifiedBeforeSwap != 0) _settleOrTake(unspecifiedCurrency, deltaUnspecifiedBeforeSwap);
        
        BeforeSwapDelta beforeSwapDelta = toBeforeSwapDelta(deltaSpecified, deltaUnspecifiedBeforeSwap);
        //ตรงนี้ pack ค่าเฉยๆ
        return (IHooks.beforeSwap.selector, beforeSwapDelta, 0);
    }

    function afterSwap(
        address, /* sender **/
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta, /* delta **/
        bytes calldata /* hookData **/
    ) external override onlyPoolManager returns (bytes4, int128) {
        (, Currency unspecifiedCurrency) = _sortCurrencies(key, params);
        _settleOrTake(unspecifiedCurrency, deltaUnspecifiedAfterSwap);

        return (IHooks.afterSwap.selector, deltaUnspecifiedAfterSwap);
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
        // positive amount means positive delta for the hook, so it can take
        // negative it should settle
        // case 1 
        // เรียกมาจาก function beforeSwap
        // specifiedCurrency = token 0
        // delta = -1e6
        if (delta > 0) {
            // case 1
            // if(-1e6 > 0)
            // if(false)
            currency.take(manager, address(this), uint128(delta), false);
        } else {
            // case 1
            // เข้า else
            uint256 amount = uint256(-int256(delta));
            // case 1
            // uint256 amount = uint256(-int256(-1e6));
            // uint256 amount = 1e6;
            if (currency.isAddressZero()) {
                // case 1
                // if(false)
                manager.settle{value: amount}();
            } else {
                // case 1 
                // เข้า token0.settle โดยใช้ lib CurrencySettler
                // โดย manager = address poolManager
                // payer = address ของ hook
                // amount = hookDeltaSpecified = -1e6
                // burn = false
                currency.settle(manager, address(this), amount, false);
            }
        }
    }
}
