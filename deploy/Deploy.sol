// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ArbitrumReceiver } from 'lib/xchain-helpers/src/receivers/ArbitrumReceiver.sol';
import { OptimismReceiver } from 'lib/xchain-helpers/src/receivers/OptimismReceiver.sol';

import { Executor } from 'src/Executor.sol';

library Deploy {

    function deployExecutor(uint256 delay, uint256 gracePeriod)
        internal returns (address executor)
    {
        executor = address(new Executor(delay, gracePeriod));
    }

    function deployArbitrumReceiver(address l1Authority, address executor)
        internal returns (address receiver)
    {
        receiver = address(new ArbitrumReceiver(l1Authority, executor));
    }

    function deployOptimismReceiver(address l1Authority, address executor)
        internal returns (address receiver)
    {
        receiver = address(new OptimismReceiver(l1Authority, executor));
    }

    function setUpExecutorPermissions(address executor_, address receiver, address deployer)
        internal
    {
        // NOTE: Using implementation instead of interface because OZ didn't define
        //       DEFAULT_ADMIN_ROLE in the IAccessControl interface.
        Executor executor = Executor(executor_);

        executor.grantRole(executor.SUBMISSION_ROLE(),     receiver);
        executor.revokeRole(executor.DEFAULT_ADMIN_ROLE(), deployer);
    }

}
