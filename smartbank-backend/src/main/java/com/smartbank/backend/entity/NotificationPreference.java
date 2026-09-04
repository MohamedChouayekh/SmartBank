package com.smartbank.backend.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "notification_preferences")
public class NotificationPreference {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // =========================================================
    // UTILISATEUR
    // =========================================================

    @OneToOne
    @JoinColumn(
            name = "user_id",
            nullable = false,
            unique = true
    )
    private User user;

    // =========================================================
    // PRÉFÉRENCES
    // =========================================================

    @Column(nullable = false)
    private boolean generalNotifications = true;

    @Column(nullable = false)
    private boolean transfers = true;

    @Column(nullable = false)
    private boolean cardPayments = true;

    @Column(nullable = false)
    private boolean withdrawals = true;

    @Column(nullable = false)
    private boolean securityAlerts = true;

    @Column(nullable = false)
    private boolean promotions = false;

    // =========================================================
    // CONSTRUCTEUR
    // =========================================================

    public NotificationPreference() {
    }

    // =========================================================
    // GETTERS / SETTERS
    // =========================================================

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public boolean isGeneralNotifications() {
        return generalNotifications;
    }

    public void setGeneralNotifications(boolean generalNotifications) {
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