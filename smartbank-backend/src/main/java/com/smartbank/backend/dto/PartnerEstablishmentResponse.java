package com.smartbank.backend.dto;

import com.smartbank.backend.entity.PartnerEstablishment;

import java.math.BigDecimal;

public class PartnerEstablishmentResponse {

    private Long id;
    private String name;
    private String category;
    private String city;
    private String address;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private boolean active;

    public PartnerEstablishmentResponse() {
    }

    public PartnerEstablishmentResponse(PartnerEstablishment establishment) {
        this.id = establishment.getId();
        this.name = establishment.getName();
        this.category = establishment.getCategory();
        this.city = establishment.getCity();
        this.address = establishment.getAddress();
        this.latitude = establishment.getLatitude();
        this.longitude = establishment.getLongitude();
        this.active = establishment.isActive();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
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

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}