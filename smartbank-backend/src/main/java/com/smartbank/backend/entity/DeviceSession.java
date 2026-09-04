package com.smartbank.backend.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "device_sessions",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_user_device",
                        columnNames = {"user_id", "device_identifier"}
                )
        }
)
public class DeviceSession {

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
    // IDENTIFIANT APPAREIL
    // =========================================================

    @Column(
            name = "device_identifier",
            nullable = false,
            length = 255
    )
    private String deviceIdentifier;

    // =========================================================
    // INFORMATIONS APPAREIL
    // =========================================================

    @Column(nullable = false, length = 100)
    private String deviceName;

    @Column(nullable = false, length = 50)
    private String deviceType;

    @Column(length = 100)
    private String browser;

    // =========================================================
    // SESSION
    // =========================================================

    @Column(nullable = false)
    private boolean current = false;

    @Column(nullable = false)
    private boolean active = true;

    @Column(name = "last_activity")
    private LocalDateTime lastActivity;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    // =========================================================
    // CONSTRUCTEUR
    // =========================================================

    public DeviceSession() {
    }

    // =========================================================
    // PREPERSIST
    // =========================================================

    @PrePersist
    protected void onCreate() {

        LocalDateTime now = LocalDateTime.now();

        this.createdAt = now;
        this.lastActivity = now;
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

    public String getDeviceName() {
        return deviceName;
    }

    public void setDeviceName(String deviceName) {
        this.deviceName = deviceName;
    }

    public String getDeviceType() {
        return deviceType;
    }

    public void setDeviceType(String deviceType) {
        this.deviceType = deviceType;
    }

    public String getBrowser() {
        return browser;
    }

    public void setBrowser(String browser) {
        this.browser = browser;
    }

    public boolean isCurrent() {
        return current;
    }

    public void setCurrent(boolean current) {
        this.current = current;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public LocalDateTime getLastActivity() {
        return lastActivity;
    }

    public void setLastActivity(LocalDateTime lastActivity) {
        this.lastActivity = lastActivity;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}