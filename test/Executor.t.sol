// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import { IExecutor } from 'src/interfaces/IExecutor.sol';
import { Executor }  from 'src/Executor.sol';

contract DefaultPayload {
    event TestEvent();
    function execute() external {
        emit TestEvent();
    }
}

contract PayablePayload {
    event TestEvent();
    function execute() external payable {
        emit TestEvent();
    }
}

contract RevertingPayload {
    function execute() external pure {
        revert("An error occurred");
    }
}

contract ExecutorTestBase is Test {

    struct Action {
        address[] targets;
        uint256[] values;
        string[]  signatures;
        bytes[]   calldatas;
        bool[]    withDelegatecalls;
    }

    event ActionsSetQueued(
        uint256 indexed id,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        bool[] withDelegatecalls,
        uint256 executionTime
    );
    event ActionsSetExecuted(
        uint256 indexed id,
        address indexed initiatorExecution,
        bytes[] returnedData
    );
    event ActionsSetCanceled(uint256 indexed id);
    event DelayUpdate(uint256 oldDelay, uint256 newDelay);
    event GracePeriodUpdate(uint256 oldGracePeriod, uint256 newGracePeriod);
    event TestEvent();

    uint256 constant DELAY        = 1 days;
    uint256 constant GRACE_PERIOD = 30 days;

    address bridge   = makeAddr("bridge");
    address guardian = makeAddr("guardian");

    Executor executor;

    function setUp() public {
        executor = new Executor({
            delay_:       DELAY,
            gracePeriod_: GRACE_PERIOD
        });
        executor.grantRole(executor.SUBMISSION_ROLE(),     bridge);
        executor.grantRole(executor.GUARDIAN_ROLE(),       guardian);
        executor.revokeRole(executor.DEFAULT_ADMIN_ROLE(), address(this));
    }

    /******************************************************************************************************************/
    /*** Helper functions                                                                                           ***/
    /******************************************************************************************************************/

    function _getDefaultAction() internal returns (Action memory) {
        address[] memory targets = new address[](1);
        targets[0] = address(new DefaultPayload());
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        string[] memory signatures = new string[](1);
        signatures[0] = "execute()";
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        bool[] memory withDelegatecalls = new bool[](1);
        withDelegatecalls[0] = true;

        return Action({
            targets:           targets,
            values:            values,
            signatures:        signatures,
            calldatas:         calldatas,
            withDelegatecalls: withDelegatecalls
        });
    }

    function _queueAction(Action memory action) internal {
        vm.prank(bridge);
        executor.queue(
            action.targets,
            action.values,
            action.signatures,
            action.calldatas,
            action.withDelegatecalls
        );
    }

    function _queueAction() internal {
        _queueAction(_getDefaultAction());
    }

    function _queueActionWithValue(uint256 value) internal {
        Action memory action = _getDefaultAction();
        action.targets[0] = address(new PayablePayload());
        action.values[0]  = value;
        _queueAction(action);
    }

    function _assertActionSet(uint256 id, bool executed, bool canceled, uint256 executionTime, Action memory action) internal view {
        IExecutor.ActionsSet memory actionsSet = executor.getActionsSetById(id);
        assertEq(actionsSet.targets,           action.targets);
        assertEq(actionsSet.values,            action.values);
        assertEq(actionsSet.signatures,        action.signatures);
        assertEq(actionsSet.calldatas,         action.calldatas);
        assertEq(actionsSet.withDelegatecalls, action.withDelegatecalls);
        assertEq(actionsSet.executionTime,     executionTime);
        assertEq(actionsSet.executed,          executed);
        assertEq(actionsSet.canceled,          canceled);
    }

}

contract ExecutorConstructorTests is ExecutorTestBase {

    function test_constructor_invalidInitParams_boundary() public {
        vm.expectRevert(abi.encodeWithSignature("GracePeriodTooShort()"));
        executor = new Executor({
            delay_:       DELAY,
            gracePeriod_: 10 minutes - 1
        });

        executor = new Executor({
            delay_:       DELAY,
            gracePeriod_: 10 minutes
        });
    }

    function test_constructor() public {
        vm.expectEmit();
        emit DelayUpdate(0, DELAY);
        vm.expectEmit();
        emit GracePeriodUpdate(0, GRACE_PERIOD);
        executor = new Executor({
            delay_:       DELAY,
            gracePeriod_: GRACE_PERIOD
        });

        assertEq(executor.delay(),       DELAY);
        assertEq(executor.gracePeriod(), GRACE_PERIOD);

        assertEq(executor.hasRole(executor.DEFAULT_ADMIN_ROLE(), address(this)),     true);
        assertEq(executor.hasRole(executor.DEFAULT_ADMIN_ROLE(), address(executor)), true);
    }

}

contract ExecutorQueueTests is ExecutorTestBase {

    function test_queue_onlySubmissionRole() public {
        vm.expectRevert(abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", address(this), executor.SUBMISSION_ROLE()));
        executor.queue(new address[](0), new uint256[](0), new string[](0), new bytes[](0), new bool[](0));
    }

    function test_queue_lengthZero() public {
        vm.expectRevert(abi.encodeWithSignature("EmptyTargets()"));
        vm.prank(bridge);
        executor.queue(new address[](0), new uint256[](0), new string[](0), new bytes[](0), new bool[](0));
    }

    function test_queue_inconsistentParamsLength() public {
        vm.expectRevert(abi.encodeWithSignature("InconsistentParamsLength()"));
        vm.prank(bridge);
        executor.queue(new address[](2), new uint256[](1), new string[](1), new bytes[](1), new bool[](1));

        vm.expectRevert(abi.encodeWithSignature("InconsistentParamsLength()"));
        vm.prank(bridge);
        executor.queue(new address[](1), new uint256[](2), new string[](1), new bytes[](1), new bool[](1));

        vm.expectRevert(abi.encodeWithSignature("InconsistentParamsLength()"));
        vm.prank(bridge);
        executor.queue(new address[](1), new uint256[](1), new string[](2), new bytes[](1), new bool[](1));

        vm.expectRevert(abi.encodeWithSignature("InconsistentParamsLength()"));
        vm.prank(bridge);
        executor.queue(new address[](1), new uint256[](1), new string[](1), new bytes[](2), new bool[](1));

        vm.expectRevert(abi.encodeWithSignature("InconsistentParamsLength()"));
        vm.prank(bridge);
        executor.queue(new address[](1), new uint256[](1), new string[](1), new bytes[](1), new bool[](2));
    }

    function test_queue() public {
        Action memory action = _getDefaultAction();

        assertEq(executor.actionsSetCount(),           0);

        vm.expectEmit(address(executor));
        emit ActionsSetQueued(
            0,
            action.targets,
            action.values,
            action.signatures,
            action.calldatas,
            action.withDelegatecalls,
            block.timestamp + DELAY
        );
        _queueAction(action);

        assertEq(executor.actionsSetCount(),           1);
        _assertActionSet({
            id:            0,
            executed:      false,
            canceled:      false,
            executionTime: block.timestamp + DELAY,
            action:        action
        });

        // Can queue up the same action 1 second later
        skip(1);
        vm.expectEmit(address(executor));
        emit ActionsSetQueued(
            1,
            action.targets,
            action.values,
            action.signatures,
            action.calldatas,
            action.withDelegatecalls,
            block.timestamp + DELAY
        );
        _queueAction(action);

        assertEq(executor.actionsSetCount(),           2);
        _assertActionSet({
            id:            1,
            executed:      false,
            canceled:      false,
            executionTime: block.timestamp + DELAY,
            action:        action
        });
    }

}

contract ExecutorExecuteTests is ExecutorTestBase {

    function test_execute_actionsSetIdTooHigh_boundary() public {
        assertEq(executor.actionsSetCount(),    0);
        vm.expectRevert(abi.encodeWithSignature("InvalidActionsSetId()"));
        executor.execute(0);

        _queueAction();
        skip(DELAY);

        assertEq(executor.actionsSetCount(),    1);
        executor.execute(0);
    }

    function test_execute_notQueued_cancelled() public {
        _queueAction();
        vm.prank(guardian);
        executor.cancel(0);

        vm.expectRevert(abi.encodeWithSignature("OnlyQueuedActions()"));
        executor.execute(0);
    }

    function test_execute_notQueued_executed() public {
        _queueAction();
        skip(DELAY);

        executor.execute(0);

        vm.expectRevert(abi.encodeWithSignature("OnlyQueuedActions()"));
        executor.execute(0);
    }

    function test_execute_notQueued_expired_boundary() public {
        _queueAction();
        skip(DELAY + GRACE_PERIOD + 1);

        vm.expectRevert(abi.encodeWithSignature("OnlyQueuedActions()"));
        executor.execute(0);

        vm.warp(block.timestamp - 1);

        executor.execute(0);
    }

    function test_execute_timelockNotFinished_boundary() public {
        _queueAction();
        skip(DELAY - 1);

        vm.expectRevert(abi.encodeWithSignature("TimelockNotFinished()"));
        executor.execute(0);

        skip(1);

        executor.execute(0);
    }

    function test_execute_balanceTooLow_boundary() public {
        _queueActionWithValue(1 ether);
        skip(DELAY);

        vm.deal(address(executor), 1 ether - 1);
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        executor.execute(0);

        vm.deal(address(executor), 1 ether);

        executor.execute(0);
    }

    function test_execute_delegateCallEvmError() public {
        // Trigger some evm error like trying to call a non-payable function
        Action memory action = _getDefaultAction();
        action.values[0] = 1 ether;
        _queueAction(action);
        skip(DELAY);
        vm.deal(address(executor), 1 ether);

        vm.expectRevert(abi.encodeWithSignature("FailedInnerCall()"));
        executor.execute(0);
    }

    function test_execute_delegateCallRevertError() public {
        Action memory action = _getDefaultAction();
        action.targets[0] = address(new RevertingPayload());
        _queueAction(action);
        skip(DELAY);

        // Should return the underlying error message
        vm.expectRevert("An error occurred");
        executor.execute(0);
    }

    function test_execute_delegateCallEmptyContract() public {
        Action memory action = _getDefaultAction();
        action.targets[0] = makeAddr("emptyContract");
        _queueAction(action);
        skip(DELAY);

        vm.expectRevert(abi.encodeWithSignature("AddressEmptyCode(address)", action.targets[0]));
        executor.execute(0);
    }

    function test_execute_callEvmError() public {
        // Trigger some evm error like trying to call a non-payable function
        Action memory action = _getDefaultAction();
        action.values[0]            = 1 ether;
        action.withDelegatecalls[0] = false;
        _queueAction(action);
        skip(DELAY);
        vm.deal(address(executor), 1 ether);

        vm.expectRevert(abi.encodeWithSignature("FailedInnerCall()"));
        executor.execute(0);
    }

    function test_execute_callRevertError() public {
        Action memory action = _getDefaultAction();
        action.targets[0]           = address(new RevertingPayload());
        action.withDelegatecalls[0] = false;
        _queueAction(action);
        skip(DELAY);

        // Should return the underlying error message
        vm.expectRevert("An error occurred");
        executor.execute(0);
    }

    function test_execute_callEmptyContract() public {
        Action memory action = _getDefaultAction();
        action.targets[0]           = makeAddr("emptyContract");
        action.withDelegatecalls[0] = false;
        _queueAction(action);
        skip(DELAY);

        vm.expectRevert(abi.encodeWithSignature("AddressEmptyCode(address)", action.targets[0]));
        executor.execute(0);
    }

    function test_execute_delegateCall() public {
        Action memory action = _getDefaultAction();
        _queueAction(action);
        skip(DELAY);

        assertEq(executor.getActionsSetById(0).executed, false);
        assertEq(uint8(executor.getCurrentState(0)),     uint8(IExecutor.ActionsSetState.Queued));

        bytes[] memory returnedData = new bytes[](1);
        returnedData[0] = "";
        vm.expectEmit(address(executor));
        emit TestEvent();
        vm.expectEmit(address(executor));
        emit ActionsSetExecuted(0, address(this), returnedData);
        executor.execute(0);

        assertEq(executor.getActionsSetById(0).executed, true);
        assertEq(uint8(executor.getCurrentState(0)),     uint8(IExecutor.ActionsSetState.Executed));
    }

    function test_execute_call() public {
        Action memory action = _getDefaultAction();
        action.withDelegatecalls[0] = false;
        _queueAction(action);
        skip(DELAY);

        assertEq(executor.getActionsSetById(0).executed, false);
        assertEq(uint8(executor.getCurrentState(0)),     uint8(IExecutor.ActionsSetState.Queued));

        bytes[] memory returnedData = new bytes[](1);
        returnedData[0] = "";
        vm.expectEmit(action.targets[0]);
        emit TestEvent();
        vm.expectEmit(address(executor));
        emit ActionsSetExecuted(0, address(this), returnedData);
        executor.execute(0);

        assertEq(executor.getActionsSetById(0).executed, true);
        assertEq(uint8(executor.getCurrentState(0)),     uint8(IExecutor.ActionsSetState.Executed));
    }

    function test_execute_delegateCallWithCalldata() public {
        Action memory action = _getDefaultAction();
        action.signatures[0] = "";
        action.calldatas[0]  = abi.encodeWithSignature("execute()");
        _queueAction(action);
        skip(DELAY);

        assertEq(executor.getActionsSetById(0).executed, false);
        assertEq(uint8(executor.getCurrentState(0)),     uint8(IExecutor.ActionsSetState.Queued));

        bytes[] memory returnedData = new bytes[](1);
        returnedData[0] = "";
        vm.expectEmit(address(executor));
        emit TestEvent();
        vm.expectEmit(address(executor));
        emit ActionsSetExecuted(0, address(this), returnedData);
        executor.execute(0);

        assertEq(executor.getActionsSetById(0).executed, true);
        assertEq(uint8(executor.getCurrentState(0)),     uint8(IExecutor.ActionsSetState.Executed));
    }

    function test_execute_callWithCalldata() public {
        Action memory action = _getDefaultAction();
        action.signatures[0]        = "";
        action.calldatas[0]         = abi.encodeWithSignature("execute()");
        action.withDelegatecalls[0] = false;
        _queueAction(action);
        skip(DELAY);

        assertEq(executor.getActionsSetById(0).executed, false);
        assertEq(uint8(executor.getCurrentState(0)),     uint8(IExecutor.ActionsSetState.Queued));

        bytes[] memory returnedData = new bytes[](1);
        returnedData[0] = "";
        vm.expectEmit(action.targets[0]);
        emit TestEvent();
        vm.expectEmit(address(executor));
        emit ActionsSetExecuted(0, address(this), returnedData);
        executor.execute(0);

        assertEq(executor.getActionsSetById(0).executed, true);
        assertEq(uint8(executor.getCurrentState(0)),     uint8(IExecutor.ActionsSetState.Executed));
    }

}

contract ExecutorCancelTests is ExecutorTestBase {

    function test_cancel_notGuardian() public {
        _queueAction();
        skip(DELAY);

        vm.expectRevert(abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", address(this), executor.GUARDIAN_ROLE()));
        executor.cancel(0);
    }

    function test_cancel_actionsSetIdTooHigh_boundary() public {
        assertEq(executor.actionsSetCount(),    0);
        vm.expectRevert(abi.encodeWithSignature("InvalidActionsSetId()"));
        vm.prank(guardian);
        executor.cancel(0);

        _queueAction();
        skip(DELAY);

        assertEq(executor.actionsSetCount(),    1);
        vm.prank(guardian);
        executor.cancel(0);
    }

    function test_cancel_notQueued_cancelled() public {
        _queueAction();
        vm.prank(guardian);
        executor.cancel(0);

        vm.expectRevert(abi.encodeWithSignature("OnlyQueuedActions()"));
        vm.prank(guardian);
        executor.cancel(0);
    }

    function test_cancel_notQueued_executed() public {
        _queueAction();
        skip(DELAY);

        executor.execute(0);

        vm.expectRevert(abi.encodeWithSignature("OnlyQueuedActions()"));
        vm.prank(guardian);
        executor.cancel(0);
    }

    function test_cancel_notQueued_expired_boundary() public {
        _queueAction();
        skip(DELAY + GRACE_PERIOD + 1);

        vm.expectRevert(abi.encodeWithSignature("OnlyQueuedActions()"));
        vm.prank(guardian);
        executor.cancel(0);

        vm.warp(block.timestamp - 1);

        vm.prank(guardian);
        executor.cancel(0);
    }

    function test_cancel() public {
        Action memory action = _getDefaultAction();
        _queueAction(action);

        assertEq(executor.getActionsSetById(0).canceled, false);
        assertEq(uint8(executor.getCurrentState(0)),     uint8(IExecutor.ActionsSetState.Queued));

        vm.expectEmit(address(executor));
        emit ActionsSetCanceled(0);
        vm.prank(guardian);
        executor.cancel(0);

        assertEq(executor.getActionsSetById(0).canceled, true);
        assertEq(uint8(executor.getCurrentState(0)),     uint8(IExecutor.ActionsSetState.Canceled));
    }

}

contract ExecutorUpdateTests is ExecutorTestBase {

    function test_updateDelay_notSelf() public {
        vm.expectRevert(abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", address(this), executor.DEFAULT_ADMIN_ROLE()));
        executor.updateDelay(2 days);
    }

    function test_updateDelay() public {
        assertEq(executor.delay(), 1 days);

        vm.expectEmit(address(executor));
        emit DelayUpdate(1 days, 2 days);
        vm.prank(address(executor));
        executor.updateDelay(2 days);

        assertEq(executor.delay(), 2 days);
    }

    function test_updateGracePeriod_notSelf() public {
        vm.expectRevert(abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", address(this), executor.DEFAULT_ADMIN_ROLE()));
        executor.updateGracePeriod(60 days);
    }

    function test_updateGracePeriod_underMinimum_boundary() public {
        vm.expectRevert(abi.encodeWithSignature("GracePeriodTooShort()"));
        vm.prank(address(executor));
        executor.updateGracePeriod(10 minutes - 1);

        vm.prank(address(executor));
        executor.updateGracePeriod(10 minutes);
    }

    function test_updateGracePeriod() public {
        assertEq(executor.gracePeriod(), 30 days);

        vm.expectEmit(address(executor));
        emit GracePeriodUpdate(30 days, 60 days);
        vm.prank(address(executor));
        executor.updateGracePeriod(60 days);

        assertEq(executor.gracePeriod(), 60 days);
    }

}

contract ExecutorMiscTests is ExecutorTestBase {

    function test_executeDelegateCall_notSelf() public {
        vm.expectRevert(abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", address(this), executor.DEFAULT_ADMIN_ROLE()));
        executor.executeDelegateCall(address(0), "");
    }

    function test_executeDelegateCall() public {
        address target = address(new DefaultPayload());

        vm.expectEmit(address(executor));
        emit TestEvent();
        vm.prank(address(executor));
        executor.executeDelegateCall(target, abi.encodeCall(DefaultPayload.execute, ()));
    }

    function test_receiveFunds() public {
        assertEq(address(executor).balance, 0);

        executor.receiveFunds{value:1 ether}();

        assertEq(address(executor).balance, 1 ether);
    }

}
