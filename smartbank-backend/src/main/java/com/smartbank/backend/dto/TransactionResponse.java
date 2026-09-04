package com.smartbank.backend.dto;

import com.smartbank.backend.entity.Transaction;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class TransactionResponse {

    private Long id;

    private Long accountId;

    private String accountNumber;

    private String type;

    private BigDecimal amount;

    private String label;

    private String reference;

    private String relatedAccountNumber;

    private LocalDateTime createdAt;

    public TransactionResponse(Transaction transaction) {

        this.id = transaction.getId();

        this.accountId =
                transaction.getAccount().getId();

        this.accountNumber =
                transaction.getAccount()
                        .getAccountNumber();

        this.type =
                transaction.getType();

        this.amount =
                transaction.getAmount();

        this.label =
                transaction.getLabel();

        this.reference =
                transaction.getReference();

        this.relatedAccountNumber =
                transaction.getRelatedAccountNumber();

        this.createdAt =
                transaction.getCreatedAt();
    }

    public Long getId() {
        return id;
    }

    public Long getAccountId() {
        return accountId;
    }

    public String getAccountNumber() {
        return accountNumber;
    }

    public String getType() {
        return type;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public String getLabel() {
        return label;
    }

    public String getReference() {
        return reference;
    }

    public String getRelatedAccountNumber() {
        return relatedAccountNumber;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}