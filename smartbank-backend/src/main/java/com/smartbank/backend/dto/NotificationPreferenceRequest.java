package com.smartbank.backend.dto;

public class NotificationPreferenceRequest {

    private boolean generalNotifications;
    private boolean transfers;
    private boolean cardPayments;
    private boolean withdrawals;
    private boolean securityAlerts;
    private boolean promotions;

    public NotificationPreferenceRequest() {
    }

    public boolean isGeneralNotifications() {
        return generalNotifications;
    }

    public void setGeneralNotifications(
            boolean generalNotifications) {

        this.generalNotifications =
                generalNotifications;
    }

    public boolean isTransfers() {
        return transfers;
    }

    public void setTransfers(boolean transfers) {
        this.transfers = transfers;
    }

    public boolean isCardPayments() {
        return cardPayments;
    }

    public void setCardPayments(boolean cardPayments) {
        this.cardPayments = cardPayments;
    }

    public boolean isWithdrawals() {
        return withdrawals;
    }

    public void setWithdrawals(boolean withdrawals) {
        this.withdrawals = withdrawals;
    }

    public boolean isSecurityAlerts() {
        return securityAlerts;
    }

    public void setSecurityAlerts(
            boolean securityAlerts) {

        this.securityAlerts = securityAlerts;
    }

    public boolean isPromotions() {
        return promotions;
    }

    public void setPromotions(boolean promotions) {
        this.promotions = promotions;
    }
}