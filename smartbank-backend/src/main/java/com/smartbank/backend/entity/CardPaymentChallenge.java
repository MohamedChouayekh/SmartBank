package com.smartbank.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "card_payment_challenges")
public class CardPaymentChallenge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "count_current_cycle", nullable = false)
    private Integer countCurrentCycle = 0;

    @Column(name = "cycle_start_at")
    private LocalDateTime cycleStartAt;

    @Column(nullable = false, length = 20)
    private String status = "ACTIVE";

    @PrePersist
    protected void onCreate() {
        if (cycleStartAt == null) {
            cycleStartAt = LocalDateTime.now();
        }
    }

    public CardPaymentChallenge() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Integer getCountCurrentCycle() { return countCurrentCycle; }
    public void setCountCurrentCycle(Integer countCurrentCycle) { this.countCurrentCycle = countCurrentCycle; }

    public LocalDateTime getCycleStartAt() { return cycleStartAt; }
    public void setCycleStartAt(LocalDateTime cycleStartAt) { this.cycleStartAt = cycleStartAt; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}