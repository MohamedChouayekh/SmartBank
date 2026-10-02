package com.smartbank.backend.dto;

import com.smartbank.backend.entity.PartnerEstablishment;
import com.smartbank.backend.entity.PartnerPromotion;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class PartnerPromotionResponse {

    private Long id;
    private Long partnerEstablishmentId;
    private String establishmentName;
    private String category;
    private String city;
    private String address;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private BigDecimal discountPercent;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private String description;
    private boolean active;

    public PartnerPromotionResponse() {
    }

    public PartnerPromotionResponse(PartnerPromotion promotion) {
        PartnerEstablishment establishment = promotion.getPartnerEstablishment();

        this.id = promotion.getId();
        this.partnerEstablishmentId = establishment.getId();
        this.establishmentName = establishment.getName();
        this.category = establishment.getCategory();
        this.city = establishment.getCity();
        this.address = establishment.getAddress();
        this.latitude = establishment.getLatitude();
        this.longitude = establishment.getLongitude();
        this.discountPercent = promotion.getDiscountPercent();
        this.startDate = promotion.getStartDate();
        this.endDate = promotion.getEndDate();
        this.description = promotion.getDescription();
        this.active = promotion.isActive();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getPartnerEstablishmentId() {
        return partnerEstablishmentId;
    }

    public void setPartnerEstablishmentId(Long partnerEstablishmentId) {
        this.partnerEstablishmentId = partnerEstablishmentId;
    }

    public String getEstablishmentName() {
        return establishmentName;
    }

    public void setEstablishmentName(String establishmentName) {
        this.establishmentName = establishmentName;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public BigDecimal getLatitude() {
        return latitude;
    }

    public void setLatitude(BigDecimal latitude) {
        this.latitude = latitude;
    }

    public BigDecimal getLongitude() {
        return longitude;
    }

    public void setLongitude(BigDecimal longitude) {
        this.longitude = longitude;
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

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}