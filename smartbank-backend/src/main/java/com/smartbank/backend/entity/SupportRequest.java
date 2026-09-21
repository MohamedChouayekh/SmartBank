package com.smartbank.backend.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "support_requests")
public class SupportRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // =========================================================
    // UTILISATEUR
    // =========================================================

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // =========================================================
    // CATÉGORIE
    // =========================================================

    @Column(nullable = false, length = 50)
    private String category;

    // =========================================================
    // SUJET
    // =========================================================

    @Column(nullable = false, length = 150)
    private String subject;

    // =========================================================
    // MESSAGE UTILISATEUR
    // =========================================================

    @Column(nullable = false, length = 2000)
    private String message;

    // =========================================================
    // RÉPONSE DE L'ADMIN
    // =========================================================

    @Column(length = 3000)
    private String adminResponse;

    // =========================================================
    // STATUT
    // =========================================================

    @Column(nullable = false, length = 30)
    private String status = "OPEN";

    // =========================================================
    // DATES
    // =========================================================

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // =========================================================
    // CONSTRUCTEUR
    // =========================================================

    public SupportRequest() {
    }

    // =========================================================
    // DATE DE CRÉATION
    // =========================================================

    @PrePersist
    protected void onCreate() {

        LocalDateTime now = LocalDateTime.now();

        if (createdAt == null) {
            createdAt = now;
        }

        if (updatedAt == null) {
            updatedAt = now;
        }

        if (status == null || status.trim().isEmpty()) {
            status = "OPEN";
        }
    }

    // =========================================================
    // DATE DE MODIFICATION
    // =========================================================

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
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

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getSubject() {
        return subject;
    }

    public void setSubject(String subject) {
        this.subject = subject;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getAdminResponse() {
        return adminResponse;
    }

    public void setAdminResponse(String adminResponse) {
        this.adminResponse = adminResponse;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}