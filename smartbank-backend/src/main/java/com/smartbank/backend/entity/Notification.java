package com.smartbank.backend.entity;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "notifications")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // =========================================================
    // UTILISATEUR QUI REÇOIT LA NOTIFICATION
    // =========================================================

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // =========================================================
    // TYPE
    // =========================================================

    @Column(nullable = false, length = 30)
    private String type;

    // =========================================================
    // TITRE
    // =========================================================

    @Column(nullable = false, length = 150)
    private String title;

    // =========================================================
    // MESSAGE
    // =========================================================

    @Column(length = 255)
    private String message;

    // =========================================================
    // LU / NON LU
    // =========================================================

    @Column(name = "is_read", nullable = false)
    private boolean read = false;

    // =========================================================
    // DATE
    // =========================================================

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    // =========================================================
    // INFORMATIONS TRANSFERT
    // =========================================================

    @Column(name = "sender_name", length = 120)
    private String senderName;

    @Column(name = "sender_account_number", length = 50)
    private String senderAccountNumber;

    @Column(name = "amount", precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(name = "source_account_type", length = 30)
    private String sourceAccountType;

    @Column(name = "destination_account_type", length = 30)
    private String destinationAccountType;

    // =========================================================
    // CONSTRUCTEUR
    // =========================================================

    public Notification() {
    }

    // =========================================================
    // DATE AUTOMATIQUE
    // =========================================================

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
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

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public boolean isRead() {
        return read;
    }

    public void setRead(boolean read) {
        this.read = read;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getSenderName() {
        return senderName;
    }

    public void setSenderName(String senderName) {
        this.senderName = senderName;
    }

    public String getSenderAccountNumber() {
        return senderAccountNumber;
    }

    public void setSenderAccountNumber(
            String senderAccountNumber) {
        this.senderAccountNumber =
                senderAccountNumber;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public String getSourceAccountType() {
        return sourceAccountType;
    }

    public void setSourceAccountType(
            String sourceAccountType) {
        this.sourceAccountType =
                sourceAccountType;
    }

    public String getDestinationAccountType() {
        return destinationAccountType;
    }

    public void setDestinationAccountType(
            String destinationAccountType) {
        this.destinationAccountType =
                destinationAccountType;
    }
}