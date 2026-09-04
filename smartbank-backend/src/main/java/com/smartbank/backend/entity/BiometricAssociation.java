package com.smartbank.backend.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "biometric_associations",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_biometric_device",
                        columnNames = {"device_identifier"}
                )
        }
)
public class BiometricAssociation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // =========================================================
    // COMPTE PROPRIÉTAIRE DE L'ASSOCIATION
    // =========================================================

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
            name = "user_id",
            nullable = false
    )
    private User user;

    // =========================================================
    // APPAREIL
    // =========================================================

    @Column(
            name = "device_identifier",
            nullable = false,
            unique = true,
            length = 255
    )
    private String deviceIdentifier;

    // =========================================================
    // ÉTAT
    // =========================================================

    @Column(nullable = false)
    private boolean enabled = false;

    // =========================================================
    // DATES
    // =========================================================

    @Column(
            name = "associated_at",
            nullable = false
    )
    private LocalDateTime associatedAt;

    @Column(name = "last_enabled_at")
    private LocalDateTime lastEnabledAt;

    @Column(name = "disabled_at")
    private LocalDateTime disabledAt;

    // =========================================================
    // CONSTRUCTEUR
    // =========================================================

    public BiometricAssociation() {
    }

    // =========================================================
    // PREPERSIST
    // =========================================================

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.associatedAt = now;

        if (this.enabled) {
            this.lastEnabledAt = now;
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

    public String getDeviceIdentifier() {
        return deviceIdentifier;
    }

    public void setDeviceIdentifier(String deviceIdentifier) {
        this.deviceIdentifier = deviceIdentifier;
    }

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public LocalDateTime getAssociatedAt() {
        return associatedAt;
    }

    public void setAssociatedAt(LocalDateTime associatedAt) {
        this.associatedAt = associatedAt;
    }

    public LocalDateTime getLastEnabledAt() {
        return lastEnabledAt;
    }

    public void setLastEnabledAt(LocalDateTime lastEnabledAt) {
        this.lastEnabledAt = lastEnabledAt;
    }

    public LocalDateTime getDisabledAt() {
        return disabledAt;
    }

    public void setDisabledAt(LocalDateTime disabledAt) {
        this.disabledAt = disabledAt;
    }
}