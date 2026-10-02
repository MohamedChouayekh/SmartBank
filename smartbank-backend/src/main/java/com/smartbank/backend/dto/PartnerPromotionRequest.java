package com.smartbank.backend.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class PartnerPromotionRequest {

    private Long partnerEstablishmentId;
    private BigDecimal discountPercent;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private Boolean active;
    private String description;

    public PartnerPromotionRequest() {
    }

    public Long getPartnerEstablishmentId() {
        return partnerEstablishmentId;
    }

    public void setPartnerEstablishmentId(Long partnerEstablishmentId) {
        this.partnerEstablishmentId = partnerEstablishmentId;
    }

    public BigDecimal getDiscountPercent() {
        return discountPercent;
    }

    public void setDiscountPercent(BigDecimal discountPercent) {
        this.discountPercent = discountPercent;
    }

    public LocalDateTime getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDateTime startDate) {
        this.startDate = startDate;
    }

    public LocalDateTime getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDateTime endDate) {
        this.endDate = endDate;
    }

    public Boolean getActive() {
        return active;
    }

    public void setActive(Boolean active) {
        this.active = active;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}