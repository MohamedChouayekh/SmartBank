package com.smartbank.backend.service;

import com.smartbank.backend.entity.Account;
import com.smartbank.backend.entity.Transaction;
import com.smartbank.backend.repository.AccountRepository;
import com.smartbank.backend.repository.TransactionRepository;

import jakarta.transaction.Transactional;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;

    private final AccountRepository accountRepository;

    private final NotificationService notificationService;

    public TransactionService(
            TransactionRepository transactionRepository,
            AccountRepository accountRepository,
            NotificationService notificationService) {

        this.transactionRepository =
                transactionRepository;

        this.accountRepository =
                accountRepository;

        this.notificationService =
                notificationService;
    }

    // =========================================================
    // TRANSACTIONS PAR COMPTE
    // =========================================================
    public List<Transaction> getTransactionsByAccount(
            Long accountId) {

        return transactionRepository
                .findByAccountIdOrderByCreatedAtDesc(
                        accountId
                );
    }

    // =========================================================
    // TRANSACTIONS PAR UTILISATEUR
    // =========================================================
    public List<Transaction> getTransactionsByUser(
            Long userId) {

        return transactionRepository
                .findByAccount_User_IdOrderByCreatedAtDesc(
                        userId
                );
    }

    // =========================================================
    // VIREMENT
    // =========================================================
    @Transactional
    public void makeTransfer(
            String fromAccountNumber,
            String toAccountNumber,
            BigDecimal amount,
            String label) {

        // =====================================================
        // VALIDATION
        // =====================================================

        if (fromAccountNumber == null ||
                fromAccountNumber.trim().isEmpty()) {

            throw new RuntimeException(
                    "Le compte source est obligatoire."
            );
        }

        if (toAccountNumber == null ||
                toAccountNumber.trim().isEmpty()) {

            throw new RuntimeException(
                    "Le compte bénéficiaire est obligatoire."
            );
        }

        fromAccountNumber =
                fromAccountNumber.trim();

        toAccountNumber =
                toAccountNumber.trim();

        if (fromAccountNumber.equals(
                toAccountNumber)) {

            throw new RuntimeException(
                    "Le compte source et le compte bénéficiaire "
                            + "doivent être différents."
            );
        }

        if (amount == null ||
                amount.compareTo(
                        BigDecimal.ZERO) <= 0) {

            throw new RuntimeException(
                    "Le montant du virement doit être supérieur à 0."
            );
        }

        // =====================================================
        // SOURCE
        // =====================================================

        Account sourceAccount =
                accountRepository
                        .findByAccountNumber(
                                fromAccountNumber
                        )
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Compte source introuvable."
                                )
                        );

        // =====================================================
        // DESTINATION
        // =====================================================

        Account destinationAccount =
                accountRepository
                        .findByAccountNumber(
                                toAccountNumber
                        )
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Compte bénéficiaire introuvable."
                                )
                        );

        // =====================================================
        // TYPES
        // =====================================================

        String sourceType =
                sourceAccount.getType() == null
                        ? ""
                        : sourceAccount.getType()
                        .trim()
                        .toUpperCase();

        String destinationType =
                destinationAccount.getType() == null
                        ? ""
                        : destinationAccount.getType()
                        .trim()
                        .toUpperCase();

        boolean sourceIsCurrent =
                "CURRENT".equals(sourceType);

        boolean sourceIsSavings =
                "SAVINGS".equals(sourceType);

        boolean destinationIsCurrent =
                "CURRENT".equals(destinationType);

        boolean destinationIsSavings =
                "SAVINGS".equals(destinationType);

        if (!sourceIsCurrent &&
                !sourceIsSavings) {

            throw new RuntimeException(
                    "Le type du compte source n'est pas autorisé."
            );
        }

        if (!destinationIsCurrent &&
                !destinationIsSavings) {

            throw new RuntimeException(
                    "Le type du compte destination n'est pas autorisé."
            );
        }

        // =====================================================
        // MÊME UTILISATEUR ?
        // =====================================================

        Long sourceUserId =
                sourceAccount
                        .getUser()
                        .getId();

        Long destinationUserId =
                destinationAccount
                        .getUser()
                        .getId();

        boolean sameUser =
                sourceUserId.equals(
                        destinationUserId
                );

        // =====================================================
        // RÈGLES MÉTIER
        // =====================================================

        if (sameUser) {

            // CURRENT -> SAVINGS
            // SAVINGS -> CURRENT
            // CURRENT -> CURRENT interdit
            // SAVINGS -> SAVINGS interdit

            boolean validInternal =
                    (sourceIsCurrent &&
                            destinationIsSavings)
                            ||
                            (sourceIsSavings &&
                                    destinationIsCurrent);

            if (!validInternal) {

                throw new RuntimeException(
                        "Entre vos propres comptes, "
                                + "le transfert est uniquement autorisé "
                                + "entre le compte courant et le compte épargne."
                );
            }

        } else {

            // =================================================
            // AUTRE CLIENT
            // CURRENT -> CURRENT UNIQUEMENT
            // =================================================

            if (!(sourceIsCurrent &&
                    destinationIsCurrent)) {

                throw new RuntimeException(
                        "Les virements vers un autre utilisateur "
                                + "sont uniquement autorisés entre "
                                + "deux comptes courants."
                );
            }
        }

        // =====================================================
        // SOLDE
        // =====================================================

        if (sourceAccount.getBalance()
                .compareTo(amount) < 0) {

            throw new RuntimeException(
                    "Solde insuffisant pour effectuer le virement."
            );
        }

        // =====================================================
        // DÉBIT
        // =====================================================

        sourceAccount.setBalance(
                sourceAccount
                        .getBalance()
                        .subtract(amount)
        );

        // =====================================================
        // CRÉDIT
        // =====================================================

        destinationAccount.setBalance(
                destinationAccount
                        .getBalance()
                        .add(amount)
        );

        accountRepository.save(
                sourceAccount
        );

        accountRepository.save(
                destinationAccount
        );

        // =====================================================
        // TRANSACTION SORTANTE
        // =====================================================

        Transaction outgoing =
                new Transaction();

        outgoing.setAccount(
                sourceAccount
        );

        outgoing.setType(
                "TRANSFER_OUT"
        );

        outgoing.setAmount(
                amount
        );

        outgoing.setLabel(
                label != null &&
                        !label.trim().isEmpty()
                        ? label.trim()
                        : "Virement"
        );

        outgoing.setRelatedAccountNumber(
                destinationAccount
                        .getAccountNumber()
        );

        // =====================================================
        // TRANSACTION ENTRANTE
        // =====================================================

        Transaction incoming =
                new Transaction();

        incoming.setAccount(
                destinationAccount
        );

        incoming.setType(
                "TRANSFER_IN"
        );

        incoming.setAmount(
                amount
        );

        incoming.setLabel(
                label != null &&
                        !label.trim().isEmpty()
                        ? label.trim()
                        : "Virement reçu"
        );

        incoming.setRelatedAccountNumber(
                sourceAccount
                        .getAccountNumber()
        );

        transactionRepository.save(
                outgoing
        );

        transactionRepository.save(
                incoming
        );

        // =====================================================
        // NUMÉRO MASQUÉ DU COMPTE ÉMETTEUR
        // =====================================================

        String maskedSenderAccount =
                maskAccountNumber(
                        sourceAccount
                                .getAccountNumber()
                );

        // =====================================================
        // NOM DE L'ÉMETTEUR
        // =====================================================

        String senderName =
                sourceAccount
                        .getUser()
                        .getFullName();

        if (senderName == null ||
                senderName.trim().isEmpty()) {

            senderName =
                    sourceAccount
                            .getUser()
                            .getUsername();
        }

        // =====================================================
        // CAS 1 : MÊME UTILISATEUR
        // =====================================================

        if (sameUser) {

            String destinationLabel;

            if (destinationIsSavings) {

                destinationLabel =
                        "votre compte épargne";

            } else {

                destinationLabel =
                        "votre compte courant";
            }

            notificationService
                    .notifyTransferDetailed(
                            sourceUserId,
                            "Transfert entre vos comptes",
                            "Vous effectuez un virement de "
                                    + amount
                                    + " TND vers "
                                    + destinationLabel
                                    + ".",
                            senderName,
                            maskedSenderAccount,
                            amount,
                            sourceType,
                            destinationType
                    );
        }

        // =====================================================
        // CAS 2 : AUTRE UTILISATEUR
        // =====================================================
        else {

            // =================================================
            // NOTIFICATION ÉMETTEUR
            // =================================================

            notificationService
                    .notifyTransferOut(
                            sourceUserId,
                            "Virement envoyé",
                            "Vous avez envoyé "
                                    + amount
                                    + " TND vers "
                                    + destinationAccount
                                    .getAccountNumber(),
                            amount
                    );

            // =================================================
            // NOTIFICATION DESTINATAIRE
            // =================================================

            notificationService
                    .notifyTransferIn(
                            destinationUserId,
                            "Virement reçu",
                            "Vous avez reçu un virement de "
                                    + senderName
                                    + ".",
                            senderName,
                            maskedSenderAccount,
                            amount,
                            sourceType,
                            destinationType
                    );
        }
    }

    // =========================================================
    // MASQUER LE NUMÉRO DU COMPTE
    // =========================================================
    private String maskAccountNumber(
            String accountNumber) {

        if (accountNumber == null ||
                accountNumber.trim().isEmpty()) {

            return "";
        }

        String clean =
                accountNumber.trim();

        if (clean.length() <= 4) {

            return clean;
        }

        return "•••• " +
                clean.substring(
                        clean.length() - 4
                );
    }

    // =========================================================
    // PAIEMENT
    // =========================================================
    @Transactional
    public void makePayment(
            String accountNumber,
            String category,
            String biller,
            String reference,
            BigDecimal amount) {

        if (amount == null ||
                amount.compareTo(
                        BigDecimal.ZERO) <= 0) {

            throw new RuntimeException(
                    "Le montant doit être supérieur à 0."
            );
        }

        if (accountNumber == null ||
                accountNumber.trim().isEmpty()) {

            throw new RuntimeException(
                    "Le compte est obligatoire."
            );
        }

        Account account =
                accountRepository
                        .findByAccountNumber(
                                accountNumber.trim()
                        )
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Compte introuvable."
                                )
                        );

        if (account.getBalance()
                .compareTo(amount) < 0) {

            throw new RuntimeException(
                    "Solde insuffisant."
            );
        }

        account.setBalance(
                account.getBalance()
                        .subtract(amount)
        );

        accountRepository.save(
                account
        );

        Transaction transaction =
                new Transaction();

        transaction.setAccount(
                account
        );

        transaction.setType(
                "PAYMENT"
        );

        transaction.setAmount(
                amount
        );

        transaction.setLabel(
                category + " - " + biller
        );

        transaction.setReference(
                reference
        );

        transactionRepository.save(
                transaction
        );

        notificationService.notifyPayment(
                account.getUser().getId(),
                "Paiement effectué",
                "Paiement de "
                        + amount
                        + " TND pour "
                        + biller
                        + " ("
                        + category
                        + ")."
        );
    }

    // =========================================================
    // RETRAIT D'ESPÈCES
    // =========================================================
    @Transactional
    public BigDecimal makeWithdrawal(
            String accountNumber,
            BigDecimal amount) {

        // =====================================================
        // VALIDATION DU MONTANT
        // =====================================================

        if (amount == null ||
                amount.compareTo(
                        BigDecimal.ZERO) <= 0) {

            throw new RuntimeException(
                    "Le montant du retrait doit être supérieur à 0."
            );
        }

        // =====================================================
        // VALIDATION DU COMPTE
        // =====================================================

        if (accountNumber == null ||
                accountNumber.trim().isEmpty()) {

            throw new RuntimeException(
                    "Le compte est obligatoire."
            );
        }

        accountNumber =
                accountNumber.trim();

        // =====================================================
        // RECHERCHE DU COMPTE
        // =====================================================

        Account account =
                accountRepository
                        .findByAccountNumber(
                                accountNumber
                        )
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Compte introuvable."
                                )
                        );

        // =====================================================
        // LE RETRAIT SE FAIT SUR LE COMPTE COURANT
        // =====================================================

        String accountType =
                account.getType() == null
                        ? ""
                        : account.getType()
                        .trim()
                        .toUpperCase();

        if (!"CURRENT".equals(accountType)) {

            throw new RuntimeException(
                    "Les retraits d'espèces sont uniquement "
                            + "autorisés depuis le compte courant."
            );
        }

        // =====================================================
        // VÉRIFICATION DU SOLDE
        // =====================================================

        if (account.getBalance()
                .compareTo(amount) < 0) {

            throw new RuntimeException(
                    "Solde insuffisant pour effectuer le retrait."
            );
        }

        // =====================================================
        // DÉBIT DU COMPTE
        // =====================================================

        account.setBalance(
                account.getBalance()
                        .subtract(amount)
        );

        accountRepository.save(
                account
        );

        // =====================================================
        // CRÉATION DE LA TRANSACTION
        // =====================================================

        Transaction transaction =
                new Transaction();

        transaction.setAccount(
                account
        );

        transaction.setType(
                "WITHDRAWAL"
        );

        transaction.setAmount(
                amount
        );

        transaction.setLabel(
                "Retrait d'espèces"
        );

        transaction.setReference(
                "ATM"
        );

        transactionRepository.save(
                transaction
        );

        // =====================================================
        // NOTIFICATION
        // =====================================================

        notificationService.notifyWithdrawal(
                account.getUser().getId(),
                "Retrait d'espèces",
                "Vous avez effectué un retrait de "
                        + amount
                        + " TND depuis votre compte courant.",
                amount
        );

        // =====================================================
        // RETOUR DU NOUVEAU SOLDE
        // =====================================================

        return account.getBalance();
    }
}