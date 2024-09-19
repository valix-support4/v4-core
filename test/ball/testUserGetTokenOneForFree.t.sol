// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {Deployers} from "../utils/Deployers.sol";
import {FeeTakingHook} from "../../src/test/FeeTakingHook.sol";
import {LPFeeTakingHook} from "../../src/test/LPFeeTakingHook.sol";
import {CustomCurveHook} from "../../src/test/CustomCurveHook.sol";
import {HookAddTenPercentToTokenZero} from "../../src/test/ball/HookAddTenPercentToTokenZero.sol";
import {IHooks} from "../../src/interfaces/IHooks.sol";
import {Hooks} from "../../src/libraries/Hooks.sol";
import {PoolSwapTest} from "../../src/test/PoolSwapTest.sol";
import {PoolId} from "../../src/types/PoolId.sol";
import {IPoolManager} from "../../src/interfaces/IPoolManager.sol";
import {Currency} from "../../src/types/Currency.sol";
import {BalanceDelta} from "../../src/types/BalanceDelta.sol";
import {SafeCast} from "../../src/libraries/SafeCast.sol";
import {console} from "forge-std/console.sol";
import {Constants} from "../utils/Constants.sol";
contract CustomAccountingTest is Test, Deployers, GasSnapshot {
    using SafeCast for *;

    address hook;

    function setUp() public {
        initializeManagerRoutersAndPoolsWithLiqBall(IHooks(address(0)));
    }

    function _setUpDeltaReturnFuzzPool() internal {
        address hookAddr = address(uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG));
        address impl = address(new HookAddTenPercentToTokenZero(manager));
        _etchHookAndInitPool(hookAddr, impl);
    }

    function _etchHookAndInitPool(address hookAddr, address implAddr) internal {
        vm.etch(hookAddr, implAddr.code);
        hook = hookAddr;
        (key,) = initPoolAndAddLiquidity(currency0, currency1, IHooks(hookAddr), 100, Constants.SQRT_PRICE_1_1, ZERO_BYTES);
    }

    function test_hook_add_token_one(
        
    ) public {
        int128 test = 1;
        _setUpDeltaReturnFuzzPool();
        currency0.transfer(hook, 6e16);
        uint currency0BalanceOfUserBeforeSwap = currency0.balanceOf(address(this));
        console.log("file: testUserGetTokenOneForFree.t.sol:48 ~ currency0BalanceOfUserBeforeSwap:", currency0BalanceOfUserBeforeSwap);
        uint currency1BalanceOfUserBeforeSwap = currency1.balanceOf(address(this));
        console.log("file: testUserGetTokenOneForFree.t.sol:50 ~ currency1BalanceOfUserBeforeSwap:", currency1BalanceOfUserBeforeSwap);
        uint currency0BalanceOfManagerBeforeSwap = currency0.balanceOf(address(manager));
        console.log("file: testUserGetTokenOneForFree.t.sol:52 ~ currency0BalanceOfManagerBeforeSwap:", currency0BalanceOfManagerBeforeSwap);
        uint currency1BalanceOfManagerBeforeSwap = currency1.balanceOf(address(manager));
        console.log("file: testUserGetTokenOneForFree.t.sol:54 ~ currency1BalanceOfManagerBeforeSwap:", currency1BalanceOfManagerBeforeSwap);
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: -(currency0BalanceOfManagerBeforeSwap * 10).toInt256(),
            sqrtPriceLimitX96: (MIN_PRICE_LIMIT)
        });
        swapRouter.swap(key, params, testSettings, ZERO_BYTES);
        uint currency0BalanceOfManagerAfterSwap = currency0.balanceOf(address(manager));
        console.log("file: testUserGetTokenOneForFree.t.sol:65 ~ currency0BalanceOfManagerAfterSwap:", currency0BalanceOfManagerAfterSwap);
        uint currency1BalanceOfManagerAfterSwap = currency1.balanceOf(address(manager));
        console.log("file: testUserGetTokenOneForFree.t.sol:67 ~ currency1BalanceOfManagerAfterSwap:", currency1BalanceOfManagerAfterSwap);
        uint currency0BalanceOfUserAfterSwap = currency0.balanceOf(address(this));
        console.log("file: testUserGetTokenOneForFree.t.sol:59 ~ currency0BalanceOfUserAfterSwap:", currency0BalanceOfUserAfterSwap);
        uint currency1BalanceOfUserAfterSwap = currency1.balanceOf(address(this));
        console.log("file: testUserGetTokenOneForFree.t.sol:61 ~ currency1BalanceOfUserAfterSwap:", currency1BalanceOfUserAfterSwap);
        assertEq(test,test, "test dummy");
    }

}
