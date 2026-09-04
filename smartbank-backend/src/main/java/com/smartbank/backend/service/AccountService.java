package com.smartbank.backend.service;

import com.smartbank.backend.entity.Account;
import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.AccountRepository;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class AccountService {

    private final AccountRepository accountRepository;
    private final UserRepository userRepository;

    // =========================================================
    // SOLDES INITIAUX DE DÉMONSTRATION
    // =========================================================

    private static final BigDecimal DEMO_INITIAL_CURRENT_BALANCE =
            new BigDecimal("5250.000");

    private static final BigDecimal DEMO_INITIAL_SAVINGS_BALANCE =
            new BigDecimal("12500.000");

    // =========================================================
    // CONSTRUCTEUR
    // =========================================================

    public AccountService(
            AccountRepository accountRepository,
            UserRepository userRepository) {

        this.accountRepository = accountRepository;
        this.userRepository = userRepository;
    }

    // =========================================================
    // CRÉER UN COMPTE BANCAIRE
    // =========================================================

    public Account createAccount(Long userId, String type) {

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "User not found with id: " + userId
                        )
                );

        Account account = new Account();

        account.setAccountNumber(
                generateAccountNumber()
        );

        account.setType(
                type.toUpperCase()
        );

        account.setBalance(
                getInitialBalanceForType(type)
        );

        account.setCurrency("TND");

        account.setUser(user);

        return accountRepository.save(account);
    }

    // =========================================================
    // SOLDE INITIAL SELON LE TYPE
    // =========================================================

    private BigDecimal getInitialBalanceForType(String type) {

        if ("CURRENT".equalsIgnoreCase(type)) {

            return DEMO_INITIAL_CURRENT_BALANCE;
        }

        if ("SAVINGS".equalsIgnoreCase(type)) {

            return DEMO_INITIAL_SAVINGS_BALANCE;
        }

        return BigDecimal.ZERO;
    }

    // =========================================================
    // RÉCUPÉRER LES COMPTES D'UN UTILISATEUR
    // =========================================================

    public List<Account> getAccountsByUserId(Long userId) {

        return accountRepository.findByUserId(userId);
    }

    // =========================================================
    // RÉCUPÉRER UN COMPTE PAR ID
    // =========================================================

    public Optional<Account> getAccountById(Long id) {

        return accountRepository.findById(id);
    }

    // =========================================================
    // RÉCUPÉRER UN COMPTE PAR NUMÉRO
    // =========================================================

    public Optional<Account> getAccountByAccountNumber(
            String accountNumber) {

        return accountRepository.findByAccountNumber(
                accountNumber.trim().toUpperCase()
        );
    }

    // =========================================================
    // RÉCUPÉRER TOUS LES COMPTES
    // =========================================================

    public List<Account> getAllAccounts() {

        return accountRepository.findAll();
    }

    // =========================================================
    // GÉNÉRER UN NUMÉRO DE COMPTE
    // =========================================================

    private String generateAccountNumber() {

        return "TN"
                + UUID.randomUUID()
                .toString()
                .replace("-", "")
                .substring(0, 12)
                .toUpperCase();
    }
}