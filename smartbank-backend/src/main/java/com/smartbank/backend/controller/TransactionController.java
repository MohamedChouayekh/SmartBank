package com.smartbank.backend.controller;

import com.smartbank.backend.dto.TransactionResponse;
import com.smartbank.backend.entity.Account;
import com.smartbank.backend.entity.Transaction;
import com.smartbank.backend.service.AccountService;
import com.smartbank.backend.service.TransactionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/transactions")
public class TransactionController {

    private final TransactionService transactionService;
    private final AccountService accountService;

    public TransactionController(
            TransactionService transactionService,
            AccountService accountService) {

        this.transactionService =
                transactionService;

        this.accountService =
                accountService;
    }

    // =========================================================
    // TRANSACTIONS PAR COMPTE
    // =========================================================

    @GetMapping("/account/{accountId}")
    public ResponseEntity<List<TransactionResponse>>
    getByAccount(
            @PathVariable Long accountId) {

        List<Transaction> transactions =
                transactionService
                        .getTransactionsByAccount(
                                accountId
                        );

        List<TransactionResponse> response =
                transactions.stream()
                        .map(TransactionResponse::new)
                        .toList();

        return ResponseEntity.ok(response);
    }

    // =========================================================
    // TRANSACTIONS PAR UTILISATEUR
    // =========================================================

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<TransactionResponse>>
    getByUser(
            @PathVariable Long userId) {

        List<Transaction> transactions =
                transactionService
                        .getTransactionsByUser(
                                userId
                        );

        List<TransactionResponse> response =
                transactions.stream()
                        .map(TransactionResponse::new)
                        .toList();

        return ResponseEntity.ok(response);
    }

    // =========================================================
    // VIREMENT
    // =========================================================

    @PostMapping("/transfer")
    public ResponseEntity<?> makeTransfer(
            @RequestBody Map<String, Object> request) {

        try {

            // =================================================
            // VALIDATION DES CHAMPS OBLIGATOIRES
            // =================================================

            if (request.get("fromAccountNumber") == null ||
                    request.get("toAccountNumber") == null ||
                    request.get("amount") == null) {

                return ResponseEntity.badRequest()
                        .body(
                                Map.of(
                                        "message",
                                        "Compte source, bénéficiaire "
                                                + "et montant obligatoires."
                                )
                        );
            }

            // =================================================
            // COMPTE SOURCE
            // =================================================

            String fromAccountNumber =
                    request
                            .get("fromAccountNumber")
                            .toString()
                            .trim();

            // =================================================
            // COMPTE DESTINATION
            // =================================================

            String toAccountNumber =
                    request
                            .get("toAccountNumber")
                            .toString()
                            .trim();

            // =================================================
            // MONTANT
            // =================================================

            BigDecimal amount;

            try {

                amount =
                        new BigDecimal(
                                request
                                        .get("amount")
                                        .toString()
                        );

            } catch (NumberFormatException e) {

                return ResponseEntity.badRequest()
                        .body(
                                Map.of(
                                        "message",
                                        "Le montant du virement est invalide."
                                )
                        );
            }

            // =================================================
            // LABEL
            // =================================================

            String label =
                    request.get("label") != null
                            ? request
                            .get("label")
                            .toString()
                            .trim()
                            : null;

            // =================================================
            // EXÉCUTION DU VIREMENT
            //
            // Toutes les règles métier sont vérifiées
            // dans TransactionService.
            // =================================================

            transactionService.makeTransfer(
                    fromAccountNumber,
                    toAccountNumber,
                    amount,
                    label
            );

            // =================================================
            // RÉCUPÉRER LES INFORMATIONS DU BÉNÉFICIAIRE
            // =================================================

            Optional<Account> beneficiaryOpt =
                    accountService
                            .getAccountByAccountNumber(
                                    toAccountNumber
                            );

            Optional<Account> sourceOpt =
                    accountService
                            .getAccountByAccountNumber(
                                    fromAccountNumber
                            );

            // =================================================
            // NOM DU BÉNÉFICIAIRE
            // =================================================

            String beneficiaryName =
                    beneficiaryOpt
                            .map(Account::getUser)
                            .map(user ->
                                    user.getFullName()
                            )
                            .orElse("");

            // =================================================
            // NOUVEAU SOLDE DU COMPTE SOURCE
            // =================================================

            BigDecimal newSourceBalance =
                    sourceOpt
                            .map(Account::getBalance)
                            .orElse(BigDecimal.ZERO);

            // =================================================
            // RÉPONSE
            // =================================================

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Virement effectué avec succès.",

                            "amount",
                            amount,

                            "beneficiaryName",
                            beneficiaryName,

                            "beneficiaryAccountNumber",
                            toAccountNumber,

                            "sourceAccountNumber",
                            fromAccountNumber,

                            "newSourceBalance",
                            newSourceBalance
                    )
            );

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(
                            Map.of(
                                    "message",
                                    e.getMessage() != null
                                            ? e.getMessage()
                                            : "Erreur lors du virement."
                            )
                    );
        }
    }

    // =========================================================
    // PAIEMENT
    // =========================================================

    @PostMapping("/payment")
    public ResponseEntity<?> makePayment(
            @RequestBody Map<String, Object> request) {

        try {

            // =================================================
            // VALIDATION DES CHAMPS OBLIGATOIRES
            // =================================================

            if (request.get("accountNumber") == null ||
                    request.get("category") == null ||
                    request.get("biller") == null ||
                    request.get("reference") == null ||
                    request.get("amount") == null) {

                return ResponseEntity.badRequest()
                        .body(
                                Map.of(
                                        "message",
                                        "Tous les champs du paiement "
                                                + "sont obligatoires."
                                )
                        );
            }

            // =================================================
            // COMPTE
            // =================================================

            String accountNumber =
                    request
                            .get("accountNumber")
                            .toString()
                            .trim();

            // =================================================
            // CATÉGORIE
            // =================================================

            String category =
                    request
                            .get("category")
                            .toString();

            // =================================================
            // FACTURIER / SERVICE
            // =================================================

            String biller =
                    request
                            .get("biller")
                            .toString();

            // =================================================
            // RÉFÉRENCE
            // =================================================

            String reference =
                    request
                            .get("reference")
                            .toString();

            // =================================================
            // MONTANT
            // =================================================

            BigDecimal amount;

            try {

                amount =
                        new BigDecimal(
                                request
                                        .get("amount")
                                        .toString()
                        );

            } catch (NumberFormatException e) {

                return ResponseEntity.badRequest()
                        .body(
                                Map.of(
                                        "message",
                                        "Le montant du paiement est invalide."
                                )
                        );
            }

            // =================================================
            // EXÉCUTION DU PAIEMENT
            // =================================================

            transactionService.makePayment(
                    accountNumber,
                    category,
                    biller,
                    reference,
                    amount
            );

            // =================================================
            // RÉPONSE
            // =================================================

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Paiement effectué avec succès.",

                            "amount",
                            amount,

                            "biller",
                            biller,

                            "category",
                            category
                    )
            );

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(
                            Map.of(
                                    "message",
                                    e.getMessage() != null
                                            ? e.getMessage()
                                            : "Erreur lors du paiement."
                            )
                    );
        }
    }
}