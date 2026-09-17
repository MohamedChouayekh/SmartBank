        package com.smartbank.backend.controller;

import com.smartbank.backend.dto.BeneficiaryInfo;
import com.smartbank.backend.entity.Account;
import com.smartbank.backend.service.AccountService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/accounts")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    // =========================================================
    // CRÉER UN COMPTE
    // =========================================================

    @PostMapping
    public ResponseEntity<?> createAccount(
            @RequestBody Map<String, Object> request) {

        try {

            if (request.get("userId") == null) {
                throw new RuntimeException(
                        "Utilisateur obligatoire."
                );
            }

            if (request.get("type") == null) {
                throw new RuntimeException(
                        "Le type de compte est obligatoire."
                );
            }

            Long userId = Long.valueOf(
                    request.get("userId").toString()
            );

            String type = request.get("type")
                    .toString()
                    .trim()
                    .toUpperCase();

            Account account =
                    accountService.createAccount(
                            userId,
                            type
                    );

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Compte créé avec succès.",

                            "id",
                            account.getId(),

                            "accountNumber",
                            account.getAccountNumber(),

                            "type",
                            account.getType(),

                            "balance",
                            account.getBalance(),

                            "currency",
                            account.getCurrency(),

                            "userId",
                            account.getUser().getId()
                    )
            );

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage() != null
                                    ? e.getMessage()
                                    : "Erreur lors de la création du compte."
                    ));
        }
    }

    // =========================================================
    // RÉCUPÉRER TOUS LES COMPTES
    // =========================================================

    @GetMapping
    public ResponseEntity<List<Account>> getAllAccounts() {
        return ResponseEntity.ok(
                accountService.getAllAccounts()
        );
    }

    // =========================================================
    // RÉCUPÉRER UN COMPTE PAR ID
    // =========================================================

    @GetMapping("/{id:\\d+}")
    public ResponseEntity<Account> getAccountById(
            @PathVariable Long id) {

        return accountService
                .getAccountById(id)
                .map(ResponseEntity::ok)
                .orElse(
                        ResponseEntity.notFound().build()
                );
    }

    // =========================================================
    // RÉCUPÉRER LES COMPTES D'UN UTILISATEUR
    // =========================================================

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Account>> getAccountsByUserId(
            @PathVariable Long userId) {

        return ResponseEntity.ok(
                accountService.getAccountsByUserId(userId)
        );
    }

    // =========================================================
    // RECHERCHER UN BÉNÉFICIAIRE PAR NUMÉRO DE COMPTE
    // =========================================================

    @GetMapping("/lookup/{accountNumber}")
    public ResponseEntity<BeneficiaryInfo> lookupByAccountNumber(
            @PathVariable String accountNumber) {

        return accountService
                .getAccountByAccountNumber(
                        accountNumber
                                .trim()
                                .toUpperCase()
                )
                .map(account -> {

                    BeneficiaryInfo info =
                            new BeneficiaryInfo(
                                    account.getAccountNumber(),
                                    account.getUser().getFullName(),
                                    account.getType()
                            );

                    return ResponseEntity.ok(info);
                })
                .orElseGet(
                        () -> ResponseEntity
                                .notFound()
                                .build()
                );
    }
}
