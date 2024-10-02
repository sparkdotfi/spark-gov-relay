// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import { OptimismReceiver } from 'lib/xchain-helpers/src/receivers/OptimismReceiver.sol';

import { Deploy } from "../deploy/Deploy.sol";

import { Executor } from 'src/Executor.sol';

contract DeployTests is Test {

    function test_deployExecutor() public {
        Executor executor = Executor(Deploy.deployExecutor(100, 1000));

        assertEq(executor.delay(),       100);
        assertEq(executor.gracePeriod(), 1000);
    }

    function test_deployOptimismReceiver() public {
        OptimismReceiver receiver = OptimismReceiver(
            Deploy.deployOptimismReceiver(makeAddr("l1Authority"), makeAddr("executor"))
        );

        assertEq(OptimismReceiver(receiver).l1Authority(), makeAddr("l1Authority"));
        assertEq(OptimismReceiver(receiver).target(),      makeAddr("executor"));
    }

    function test_setUpExecutorPermissions() public {
        Executor executor = Executor(Deploy.deployExecutor(100, 1000));

        OptimismReceiver receiver = OptimismReceiver(
            Deploy.deployOptimismReceiver(makeAddr("l1Authority"), makeAddr("executor"))
        );

        assertEq(executor.hasRole(executor.SUBMISSION_ROLE(),    address(receiver)),    false);
        assertEq(executor.hasRole(executor.DEFAULT_ADMIN_ROLE(), address(this)),        true);

        Deploy.setUpExecutorPermissions(address(executor), address(receiver));

        assertEq(executor.hasRole(executor.SUBMISSION_ROLE(),    address(receiver)),    true);
        assertEq(executor.hasRole(executor.DEFAULT_ADMIN_ROLE(), address(this)),        false);
    }

}
