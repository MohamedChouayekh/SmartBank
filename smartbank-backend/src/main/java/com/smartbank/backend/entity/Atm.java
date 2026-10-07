package com.smartbank.backend.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "atms")
public class Atm {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, length = 100)
    private String city;

    @Column(nullable = false, length = 255)
    private String address;

    @Column(name = "available_24h", nullable = false)
    private boolean available24h = true;

    @Column(name = "withdrawal_available", nullable = false)
    private boolean withdrawalAvailable = true;

    @Column(name = "deposit_available", nullable = false)
    private boolean depositAvailable = false;

    @Column(nullable = false)
    private boolean available = true;

    public Atm() {
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

    public boolean isAvailable24h() {
        return available24h;
    }

    public void setAvailable24h(boolean available24h) {
        this.available24h = available24h;
    }

    public boolean isWithdrawalAvailable() {
        return withdrawalAvailable;
    }

    public void setWithdrawalAvailable(boolean withdrawalAvailable) {
        this.withdrawalAvailable = withdrawalAvailable;
    }

    public boolean isDepositAvailable() {
        return depositAvailable;
    }

    public void setDepositAvailable(boolean depositAvailable) {
        this.depositAvailable = depositAvailable;
    }

    public boolean isAvailable() {
        return available;
    }

    public void setAvailable(boolean available) {
        this.available = available;
    }
}