# Project Context

## Snapshot

- Monorepo de Solidity + frontend web para un protocolo DAO de inversion.
- La capa on-chain usa Foundry.
- El frontend usa Vite + React + TypeScript + wagmi/viem/RainbowKit.
- Hay un flujo completo de deploy y seed local para Anvil.

## Estructura Principal

- `contracts/`: logica de protocolo en Solidity.
- `script/`: despliegues, seed local y generacion de artefactos.
- `test/`: pruebas y mocks.
- `frontend/`: app web principal.
- `contracts-sdk/`: SDK generado desde ABIs y direcciones.
- `deployments/`: JSONs de direcciones por red.
- `out/`: compilados de Foundry.

## Stack

- Foundry para build, test, format y scripts.
- OpenZeppelin upgradeable y contratos propios.
- Chainlink Brownie contracts como dependencia auxiliar.
- Frontend con `react-query`, `wagmi`, `viem`, `rainbowkit`, `tailwindcss`.

## Modulos On-Chain

- `contracts/governance/`: `GovernanceToken`, `DaoGovernor`, `TimeLock`.
- `contracts/core/`: `ProtocolCore`, `Treasury`.
- `contracts/bootstrap/`: `GenesisBonding`.
- `contracts/guardians/`: `GuardianAdministrator`, `GuardianBondEscrow`.
- `contracts/vaults/`: `VaultRegistry`, `VaultFactory`, `VaultImplementation`.
- `contracts/execution/`: `RiskManager`, `StrategyRouter`.
- `contracts/adapters/aave/`: `AaveV3Adapter`.

## Arquitectura

- `TimeLock` es la pieza administrativa central.
- `DaoGovernor` gobierna la ejecucion via timelock.
- `GovernanceToken` define el poder de voto.
- `GenesisBonding` sirve para bootstrap inicial y minteo controlado.
- `GuardianAdministrator` y `GuardianBondEscrow` manejan el sistema de guardianes.
- `ProtocolCore` y `Treasury` sostienen la capa principal de activos y reglas.
- `VaultRegistry`, `VaultFactory`, `VaultImplementation` y `StrategyRouter` forman la capa de vaults.
- `RiskManager` controla restricciones y salud de operacion.
- `AaveV3Adapter` conecta con Aave v3.

## Flujo De Despliegue

- El punto de entrada principal es `script/deploy/DeployInvestmentDao.s.sol`.
- En Anvil (`chainid == 31337`) se despliegan mocks primero y luego se inyectan en la configuracion.
- El orden de despliegue importa porque hay bootstrap de roles, minter permissions y enlaces entre contratos.
- El deploy genera `deployments/<network>.json` y regenera `contracts-sdk`.
- El seed local se hace con `script/local/SeedLocal.s.sol`.

## Comandos Utiles

- `forge build`
- `forge test`
- `forge fmt`
- `make s_deployLocal`
- `make s_seedLocal`
- `pnpm --dir frontend dev`
- `pnpm --dir frontend build`

## Frontend

- Entry point en `frontend/src/main.tsx`.
- Router en `frontend/src/app/router/AppRouter.tsx`.
- App con pantallas para dashboard, vaults, governance, guardians, treasury, risk, admin, operations y bonding.
- Hooks importantes: `useProtocolReads`, `useWriteContracts`, `useProtocolCapabilities`, `useProposalComposerModel`.
- Las direcciones y ABIs viven en `frontend/src/constants/` y se alimentan desde `contracts-sdk`.

## Archivos De Referencia

- `README.md`
- `README_DEPLOY_AND_SEED.md`
- `foundry.toml`
- `script/contracts.config.ts`
- `script/generate-contracts-sdk.ts`
- `frontend/vite.config.ts`
- `frontend/src/services/contractsService.ts`
- `frontend/src/constants/deployments.ts`

## Reglas Para Trabajar Aqui

- Antes de cambiar algo, revisar el contexto del contrato o modulo afectado.
- No revertir cambios del usuario ni asumir que el worktree esta limpio.
- Preferir `apply_patch` para editar archivos.
- Si una duda depende de estado reciente, comprobarlo antes de asumir.
- Mantener este archivo corto, util y actualizado cuando cambie la arquitectura.
