package com.smartbank.backend.dto;

import java.math.BigDecimal;

public class PaymentRequest {

    private String accountNumber;
    private String category;   // Factures, Recharges, Services (Vignette)
    private String biller;     // STEG, SONEDE, Tunisie Telecom, Ooredoo, Orange...
    private String reference;  // numéro de facture / téléphone / immatriculation
    private BigDecimal amount;

    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getBiller() { return biller; }
    public void setBiller(String biller) { this.biller = biller; }

    public String getReference() { return reference; }
    public void setReference(String reference) { this.reference = reference; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
}