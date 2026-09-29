package com.smartbank.backend.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "reward_wallets")
public class RewardWallet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "points_balance", nullable = false)
    private Integer pointsBalance = 0;

    @Column(name = "pending_amount_for_points", nullable = false, precision = 15, scale = 3)
    private BigDecimal pendingAmountForPoints = BigDecimal.ZERO;

    @Column(name = "total_cashback", nullable = false, precision = 15, scale = 3)
    private BigDecimal totalCashback = BigDecimal.ZERO;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public RewardWallet() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Integer getPointsBalance() { return pointsBalance; }
    public void setPointsBalance(Integer pointsBalance) { this.pointsBalance = pointsBalance; }

    public BigDecimal getPendingAmountForPoints() { return pendingAmountForPoints; }
    public void setPendingAmountForPoints(BigDecimal pendingAmountForPoints) { this.pendingAmountForPoints = pendingAmountForPoints; }

    public BigDecimal getTotalCashback() { return totalCashback; }
    public void setTotalCashback(BigDecimal totalCashback) { this.totalCashback = totalCashback; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}