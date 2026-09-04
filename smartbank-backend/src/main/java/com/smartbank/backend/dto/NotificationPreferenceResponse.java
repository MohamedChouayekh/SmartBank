package com.smartbank.backend.dto;

public class NotificationPreferenceResponse {

    private boolean generalNotifications;
    private boolean transfers;
    private boolean cardPayments;
    private boolean withdrawals;
    private boolean securityAlerts;
    private boolean promotions;

    public NotificationPreferenceResponse() {
    }

    public NotificationPreferenceResponse(
            boolean generalNotifications,
            boolean transfers,
            boolean cardPayments,
            boolean withdrawals,
            boolean securityAlerts,
            boolean promotions) {

        this.generalNotifications = generalNotifications;
        this.transfers = transfers;
        this.cardPayments = cardPayments;
        this.withdrawals = withdrawals;
        this.securityAlerts = securityAlerts;
        this.promotions = promotions;
    }

    public boolean isGeneralNotifications() {
        return generalNotifications;
    }

    public void setGeneralNotifications(
            boolean generalNotifications) {
        this.generalNotifications = generalNotifications;
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

    public void setSecurityAlerts(boolean securityAlerts) {
        this.securityAlerts = securityAlerts;
    }

    public boolean isPromotions() {
        return promotions;
    }

    public void setPromotions(boolean promotions) {
        this.promotions = promotions;
    }
}