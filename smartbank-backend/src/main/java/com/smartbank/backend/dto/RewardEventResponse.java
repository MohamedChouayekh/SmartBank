package com.smartbank.backend.dto;

import com.smartbank.backend.entity.RewardEvent;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class RewardEventResponse {

    private Long id;
    private String type;
    private Integer pointsDelta;
    private BigDecimal cashAmount;
    private String title;
    private String description;
    private LocalDateTime createdAt;

    public RewardEventResponse(RewardEvent event) {
        this.id = event.getId();
        this.type = event.getType();
        this.pointsDelta = event.getPointsDelta();
        this.cashAmount = event.getCashAmount();
        this.title = event.getTitle();
        this.description = event.getDescription();
        this.createdAt = event.getCreatedAt();
    }

    public Long getId() { return id; }
    public String getType() { return type; }
    public Integer getPointsDelta() { return pointsDelta; }
    public BigDecimal getCashAmount() { return cashAmount; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}