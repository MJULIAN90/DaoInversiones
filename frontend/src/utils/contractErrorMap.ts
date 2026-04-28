/**
 * Mapeo centralizado de errores del contrato
 * Mantén este archivo actualizado con los errores de los contratos
 * Formato: patterns (texto a buscar), title, message, code
 */

import type { TransactionErrorCode } from "./transactionErrors";

export interface ContractErrorMapping {
  /** Patrones de texto a buscar en el mensaje de error (case-insensitive) */
  patterns: readonly string[];
  /** Título del error mostrado al usuario */
  title: string;
  /** Mensaje amigable del error */
  message: string;
  /** Código de error para clasificación */
  code: TransactionErrorCode;
  /** Categoría del error (para debugging) */
  category?: string;
}

/**
 * Diccionario completo de errores del contrato
 * Agrega nuevos errores aquí a medida que descubras nuevos casos
 */
export const CONTRACT_ERROR_MAP: readonly ContractErrorMapping[] = [
  // ========== BONDING ERRORS ==========
  {
    patterns: ["genesisbonding__alreadyfinalized", "already finalized"],
    title: "Bonding closed",
    message: "Bonding has already been finalized and no longer accepts purchases.",
    code: "contract_revert",
    category: "bonding",
  },
  {
    patterns: ["genesisbonding__invalidtoken", "invalid token"],
    title: "Unsupported token",
    message: "This token is not supported for the requested bonding purchase.",
    code: "contract_revert",
    category: "bonding",
  },

  // ========== ERC20 / TOKEN ERRORS ==========
  {
    patterns: [
      "erc20insufficientallowance",
      "insufficient allowance",
      "erc20: transfer amount exceeds allowance",
      "transfer amount exceeds allowance",
    ],
    title: "Approval required",
    message:
      "The token approval is too low for this transaction. Approve the required amount and try again.",
    code: "contract_revert",
    category: "erc20",
  },
  {
    patterns: [
      "erc20insufficientbalance",
      "guardianbondescrow__insufficientbond",
      "erc20: transfer amount exceeds balance",
      "transfer amount exceeds balance",
    ],
    title: "Insufficient funds",
    message: "Your available token balance is too low to complete this transaction.",
    code: "insufficient_funds",
    category: "erc20",
  },

  // ========== GUARDIAN ERRORS ==========
  {
    patterns: ["guardianadministrator__alreadyapplied"],
    title: "Application already submitted",
    message:
      "You already have a guardian application in progress or an active guardian record.",
    code: "contract_revert",
    category: "guardian",
  },

  // ========== GOVERNANCE / VOTING ERRORS ==========
  {
    patterns: ["governor__votealreadycast", "already voted", "already cast"],
    title: "Already voted",
    message:
      "You have already voted on this proposal. Each address can only vote once per proposal.",
    code: "contract_revert",
    category: "governance",
  },
  {
    patterns: [
      "governor__votingisclosed",
      "voting is closed",
      "voting period has ended",
    ],
    title: "Voting period ended",
    message:
      "The voting period for this proposal has ended. Check the deadline in the proposal details.",
    code: "contract_revert",
    category: "governance",
  },
  {
    patterns: ["governor__notvotingpower", "insufficient voting power", "no voting power"],
    title: "No voting power",
    message:
      "You don't have enough voting power to vote. Make sure your governance tokens are delegated.",
    code: "contract_revert",
    category: "governance",
  },

  // ========== COMMON ERRORS ==========
  {
    patterns: ["commonerrors.zeroamount", "zero amount"],
    title: "Invalid amount",
    message: "Enter an amount greater than zero before submitting the transaction.",
    code: "contract_revert",
    category: "common",
  },
  {
    patterns: ["commonerrors.zeroaddress", "zero address"],
    title: "Invalid address",
    message: "The transaction could not be prepared because one of the required addresses is invalid.",
    code: "contract_revert",
    category: "common",
  },
  {
    patterns: ["paused", "contract is paused", "transfers are paused"],
    title: "Contract paused",
    message: "This contract function is temporarily paused. Please try again later.",
    code: "contract_revert",
    category: "common",
  },
  {
    patterns: ["unauthorized", "caller is not authorized", "access denied"],
    title: "Unauthorized",
    message: "You don't have permission to perform this action.",
    code: "contract_revert",
    category: "common",
  },
];

/**
 * Busca un error en el diccionario basado en patrones
 * @param normalizedMessage Mensaje de error normalizado (lowercase, trimmed)
 * @returns Mapeo del error si se encuentra, undefined si no hay coincidencia
 */
export function findContractError(normalizedMessage: string): ContractErrorMapping | undefined {
  return CONTRACT_ERROR_MAP.find((errorMapping) =>
    errorMapping.patterns.some((pattern) => normalizedMessage.includes(pattern)),
  );
}

/**
 * Obtiene todos los patrones disponibles para debugging/logging
 */
export function getAllErrorPatterns(): string[] {
  return Array.from(
    new Set(CONTRACT_ERROR_MAP.flatMap((error) => [...error.patterns])),
  );
}

/**
 * Obtiene todos los errores de una categoría específica
 */
export function getErrorsByCategory(category: string): ContractErrorMapping[] {
  return CONTRACT_ERROR_MAP.filter((error) => error.category === category);
}
