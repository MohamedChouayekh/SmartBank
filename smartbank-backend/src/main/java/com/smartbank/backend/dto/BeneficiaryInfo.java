package com.smartbank.backend.dto;

public class BeneficiaryInfo {

    private String accountNumber;
    private String fullName;
    private String type;

    public BeneficiaryInfo(String accountNumber, String fullName, String type) {
        this.accountNumber = accountNumber;
        this.fullName = fullName;
        this.type = type;
    }

    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
}