
package com.smartbank.backend.service;

import com.smartbank.backend.entity.Account;
import com.smartbank.backend.entity.Invoice;
import com.smartbank.backend.entity.Transaction;
import com.smartbank.backend.repository.AccountRepository;
import com.smartbank.backend.repository.InvoiceRepository;
import com.smartbank.backend.repository.TransactionRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class InvoiceService {

    private final InvoiceRepository invoiceRepository;
    private final AccountRepository accountRepository;
    private final TransactionRepository transactionRepository;
    private final NotificationService notificationService;
    private final PromotionEngineService promotionEngineService;

    public InvoiceService(
            InvoiceRepository invoiceRepository,
            AccountRepository accountRepository,
            TransactionRepository transactionRepository,
            NotificationService notificationService,
            PromotionEngineService promotionEngineService) {

        this.invoiceRepository = invoiceRepository;
        this.accountRepository = accountRepository;
        this.transactionRepository = transactionRepository;
        this.notificationService = notificationService;
        this.promotionEngineService = promotionEngineService;
    }

    @Transactional
    public List<Invoice> findInvoices(
            String biller,
            String customerReference) {

        if (biller == null || biller.isBlank()
                || customerReference == null
                || customerReference.isBlank()) {
            throw new IllegalArgumentException(
                    "Le fournisseur et la référence client sont obligatoires."
            );
        }

        return invoiceRepository
                .findByBillerIgnoreCaseAndCustomerReferenceOrderByDueDateDesc(
                        biller.trim(),
                        customerReference.trim()
                );
    }

    @Transactional
    public void payInvoice(
            String accountNumber,
            String invoiceNumber) {

        if (accountNumber == null || accountNumber.isBlank()) {
            throw new IllegalArgumentException(
                    "Le compte est obligatoire."
            );
        }

        if (invoiceNumber == null || invoiceNumber.isBlank()) {
            throw new IllegalArgumentException(
                    "Le numéro de facture est obligatoire."
            );
        }

        Invoice invoice = invoiceRepository
                .findByInvoiceNumberForUpdate(invoiceNumber.trim())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Facture introuvable."
                ));

        if ("PAID".equalsIgnoreCase(invoice.getStatus())) {
            throw new IllegalArgumentException(
                    "Cette facture a déjà été payée."
            );
        }

        if (!"UNPAID".equalsIgnoreCase(invoice.getStatus())) {
            throw new IllegalArgumentException(
                    "Le statut de cette facture ne permet pas son paiement."
            );
        }

        BigDecimal amount = invoice.getAmount();

        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException(
                    "Le montant enregistré de la facture est invalide."
            );
        }

        Account account = accountRepository
                .findByAccountNumber(accountNumber.trim())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Compte introuvable."
                ));

        String accountType = account.getType() == null
                ? ""
                : account.getType().trim().toUpperCase();

        if (!"CURRENT".equals(accountType)) {
            throw new IllegalArgumentException(
                    "Les factures doivent être payées depuis le compte courant."
            );
        }

        if (account.getBalance().compareTo(amount) < 0) {
            throw new IllegalArgumentException("Solde insuffisant.");
        }

        account.setBalance(account.getBalance().subtract(amount));
        accountRepository.save(account);

        Transaction transaction = new Transaction();
        transaction.setAccount(account);
        transaction.setType("PAYMENT");
        transaction.setAmount(amount);
        transaction.setLabel(
                "Facture " + invoice.getBiller()
                        + " - " + invoice.getInvoiceNumber()
        );
        transaction.setReference(invoice.getCustomerReference());

        transactionRepository.save(transaction);

        invoice.setStatus("PAID");
        invoice.setPaidAt(LocalDateTime.now());
        invoiceRepository.save(invoice);

        notificationService.notifyPayment(
                account.getUser().getId(),
                "Facture payée",
                "La facture " + invoice.getInvoiceNumber()
                        + " de " + invoice.getBiller()
                        + " a été payée pour " + amount + " TND."
        );

        // Les points et le challenge existants restent gérés
        // par le moteur actuel des récompenses.
        promotionEngineService.evaluatePayment(
                account,
                "Factures",
                invoice.getBiller(),
                amount
        );
    }
}