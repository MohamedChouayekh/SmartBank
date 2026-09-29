package com.smartbank.backend.entity;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "reward_events")
public class RewardEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // =========================================================
    // UTILISATEUR
    // =========================================================

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // =========================================================
    // TYPE DE RÉCOMPENSE
    //
    // Exemples :
    // POINTS
    // BILL_BONUS
    // BILL_CHALLENGE
    // CASHBACK
    // CARD_CHALLENGE
    // =========================================================

    @Column(nullable = false, length = 50)
    private String type;

    // =========================================================
    // VARIATION DE POINTS
    // =========================================================

    @Column(name = "points_delta", nullable = false)
    private Integer pointsDelta = 0;

    // =========================================================
    // VARIATION MONÉTAIRE
    //
    // Exemple :
    // +5 DT après 5 factures
    // =========================================================

    @Column(
            name = "cash_amount",
            nullable = false,
            precision = 15,
            scale = 3
    )
    private BigDecimal cashAmount = BigDecimal.ZERO;

    // =========================================================
    // TITRE
    // =========================================================

    @Column(nullable = false, length = 150)
    private String title;

    // =========================================================
    // DESCRIPTION
    // =========================================================

    @Column(nullable = false, length = 500)
    private String description;

    // =========================================================
    // RÉFÉRENCE DE L'OPÉRATION
    //
    // Peut correspondre à :
    // - référence de paiement
    // - référence facture
    // - transaction
    // =========================================================

    @Column(name = "operation_reference", length = 150)
    private String operationReference;

    // =========================================================
    // DATE
    // =========================================================

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    // =========================================================
    // CONSTRUCTEUR
    // =========================================================

    public RewardEvent() {
    }

    // =========================================================
    // PRE-PERSIST
    // =========================================================

    @PrePersist
    protected void onCreate() {

        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }

        if (pointsDelta == null) {
            pointsDelta = 0;
        }

        if (cashAmount == null) {
            cashAmount = BigDecimal.ZERO;
        }
    }

    // =========================================================
    // GETTERS / SETTERS
    // =========================================================

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public Integer getPointsDelta() {
        return pointsDelta;
    }

    public void setPointsDelta(Integer pointsDelta) {
        this.pointsDelta = pointsDelta;
    }

    public BigDecimal getCashAmount() {
        return cashAmount;
    }

    public void setCashAmount(BigDecimal cashAmount) {
        this.cashAmount = cashAmount;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getOperationReference() {
        return operationReference;
    }

    public void setOperationReference(String operationReference) {
        this.operationReference = operationReference;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}