// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test, console} from "forge-std/Test.sol";
import {DeployInvestmentDaoHarness} from "../helpers/DeployInvestmentDaoHarness.sol";
import {InvestmentDaoBootstrapHarness} from "../helpers/InvestmentDaoBootstrapHarness.sol";
import {TimeLock} from "../../contracts/governance/TimeLock.sol";
import {DaoGovernor} from "../../contracts/governance/DaoGovernor.sol";
import {GovernanceToken} from "../../contracts/governance/GovernanceToken.sol";
import {GuardianAdministrator} from "../../contracts/guardians/GuardianAdministrator.sol";
import {VaultRegistry} from "../../contracts/vaults/registry/VaultRegistry.sol";
import {GenesisBonding} from "../../contracts/bootstrap/GenesisBonding.sol";
import {ProtocolCore} from "../../contracts/core/ProtocolCore.sol";
import {RiskManager} from "../../contracts/execution/RiskManager.sol";
import {StrategyRouter} from "../../contracts/execution/StrategyRouter.sol";
import {GuardianBondEscrow} from "../../contracts/guardians/GuardianBondEscrow.sol";
import {VaultFactory} from "../../contracts/vaults/factory/VaultFactory.sol";
import {VaultImplementation} from "../../contracts/vaults/implementations/VaultImplementation.sol";

contract DeployInvestmentDaoTest is Test {
  uint256 private constant BLOCK_TIME = 12;
  uint256 private constant NONZERO_DELAY = 1 days;
	bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
  bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  bytes32 constant ADAPTER_MANAGER_ROLE = keccak256("ADAPTER_MANAGER_ROLE");

  TimeLock private timeLock;
  GovernanceToken private governanceToken;
  address private treasury;
  address private daoGovernor;
  address private protocolCore;
  address private riskManager;
  address private guardianAdministrator;
  address private guardianBondEscrow;
  address private vaultRegistry;
  address private strategyRouter;
  address private vaultImplementation;
  address private genesisBonding;
  address private vaultFactory;
  address private aaveV3Adapter;
  address private compoundV3Adapter;

  function setUp() public {
    vm.roll(100);
    vm.warp(100);

    DeployInvestmentDaoHarness deployInvestmentDao = new DeployInvestmentDaoHarness();

    (
      timeLock,
      governanceToken,
      treasury,
      daoGovernor,
      protocolCore,
      riskManager,
      guardianAdministrator,
      guardianBondEscrow,
      vaultRegistry,
      strategyRouter,
      vaultImplementation,
      genesisBonding,
      vaultFactory,
      aaveV3Adapter,
      compoundV3Adapter
    ) = deployInvestmentDao.deployForTest();

    vm.roll(block.number + 1);
    vm.warp(block.timestamp + BLOCK_TIME);
  }

  function testAnvilDeploysEveryContract() public view {
    assertNotEq(address(timeLock), address(0));
    assertNotEq(address(governanceToken), address(0));
    assertNotEq(treasury, address(0));
    assertNotEq(daoGovernor, address(0));
    assertNotEq(protocolCore, address(0));
    assertNotEq(riskManager, address(0));
    assertNotEq(guardianAdministrator, address(0));
    assertNotEq(guardianBondEscrow, address(0));
    assertNotEq(vaultRegistry, address(0));
    assertNotEq(strategyRouter, address(0));
    assertNotEq(vaultImplementation, address(0));
    assertNotEq(genesisBonding, address(0));
    assertNotEq(vaultFactory, address(0));
    assertNotEq(aaveV3Adapter, address(0));
    assertNotEq(compoundV3Adapter, address(0));
  }

  function testBootstrapExecutesImmediately() public view {
    assertEq(address(GuardianAdministrator(guardianAdministrator).bondEscrow()), guardianBondEscrow);
    assertTrue(VaultRegistry(vaultRegistry).hasRole(VaultRegistry(vaultRegistry).FACTORY_ROLE(), vaultFactory));
  }

  function testGovernorReceivesTimelockRoles() public view {
    assertTrue(timeLock.hasRole(timeLock.PROPOSER_ROLE(), daoGovernor));
    assertTrue(timeLock.hasRole(timeLock.EXECUTOR_ROLE(), daoGovernor));
    assertTrue(timeLock.hasRole(timeLock.CANCELLER_ROLE(), daoGovernor));
  }

  function testTimeLockHasAllNeededRoles() public view {}

  function testGuardianAdministratorHasSnapshotVotingPower() public view {
    uint256 proposalThreshold = DaoGovernor(payable(daoGovernor)).proposalThreshold();

    assertEq(governanceToken.getVotes(guardianAdministrator), proposalThreshold);
    assertEq(governanceToken.getPastVotes(guardianAdministrator, block.number - 1), proposalThreshold);
  }

  function testNonZeroDelayBootstrapWaitsBeforeExecution() public {
    InvestmentDaoBootstrapHarness harness = new InvestmentDaoBootstrapHarness();

    address[] memory proposers = new address[](1);
    address[] memory executors = new address[](1);
    proposers[0] = address(harness);
    executors[0] = address(harness);

    TimeLock delayedTimeLock =
      new TimeLock({minDelay: NONZERO_DELAY, proposers: proposers, executors: executors, admin: address(this)});
    VaultRegistry delayedVaultRegistry = new VaultRegistry(address(delayedTimeLock));
    address expectedFactory = makeAddr("expectedFactory");
    bytes memory data = abi.encodeWithSelector(VaultRegistry.setFactory.selector, expectedFactory);
    bytes32 salt = harness.vaultFactorySalt();

    (bytes32 operationId, bool executed) =
      harness.scheduleFromCurrentSender(delayedTimeLock, address(delayedVaultRegistry), data, salt);

    assertFalse(executed);
    assertTrue(delayedTimeLock.isOperationPending(operationId));
    assertFalse(delayedTimeLock.isOperationReady(operationId));
    assertFalse(delayedVaultRegistry.hasRole(delayedVaultRegistry.FACTORY_ROLE(), expectedFactory));

    vm.expectRevert(bytes("Timelock operation not ready"));
    harness.executeReadyFromCurrentSender(delayedTimeLock, address(delayedVaultRegistry), data, salt);

    vm.warp(block.timestamp + NONZERO_DELAY + 1);
    vm.roll(block.number + 1);

    (bytes32 executedOperationId, bool executedAfterDelay) =
      harness.executeReadyFromCurrentSender(delayedTimeLock, address(delayedVaultRegistry), data, salt);

    assertEq(executedOperationId, operationId);
    assertTrue(executedAfterDelay);
    assertTrue(delayedTimeLock.isOperationDone(operationId));
    assertTrue(delayedVaultRegistry.hasRole(delayedVaultRegistry.FACTORY_ROLE(), expectedFactory));
  }

  function testValidateRolesTimeLockInContracts() public view {
		assertTrue(GenesisBonding(genesisBonding).hasRole(DEFAULT_ADMIN_ROLE, address(timeLock)));
		assertTrue(ProtocolCore(protocolCore).hasRole(DEFAULT_ADMIN_ROLE, address(timeLock)));
		assertTrue(ProtocolCore(protocolCore).hasRole(MANAGER_ROLE, address(timeLock)));
		assertTrue(governanceToken.hasRole(DEFAULT_ADMIN_ROLE, address(timeLock)));
		assertTrue(RiskManager(riskManager).hasRole(DEFAULT_ADMIN_ROLE, address(timeLock)));
		assertTrue(RiskManager(riskManager).hasRole(MANAGER_ROLE, address(timeLock)));
    assertTrue(StrategyRouter(strategyRouter).hasRole(DEFAULT_ADMIN_ROLE, address(timeLock)));
		assertTrue(StrategyRouter(strategyRouter).hasRole(ADAPTER_MANAGER_ROLE, address(timeLock)));
		assertTrue(governanceToken.hasRole(DEFAULT_ADMIN_ROLE, address(timeLock)));
		assertTrue(GuardianBondEscrow(guardianBondEscrow).hasRole(DEFAULT_ADMIN_ROLE, address(timeLock)));
		assertTrue(VaultFactory(vaultFactory).hasRole(DEFAULT_ADMIN_ROLE, address(timeLock)));
		assertTrue(VaultRegistry(vaultRegistry).hasRole(DEFAULT_ADMIN_ROLE, address(timeLock)));
		assertFalse(VaultImplementation(vaultImplementation).hasRole(DEFAULT_ADMIN_ROLE, address(timeLock)));
  }
}
