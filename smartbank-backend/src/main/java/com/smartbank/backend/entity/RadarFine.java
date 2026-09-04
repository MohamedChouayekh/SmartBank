package com.smartbank.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "radar_fines")
public class RadarFine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String reference;

    @Column(nullable = false)
    private String nature;

    @Column(nullable = false)
    private String immatriculation;

    @Column(name = "notification_date", nullable = false)
    private LocalDate notificationDate;

    @Column(nullable = false)
    private Double amount;

    @Column(nullable = false)
    private boolean paid = false;

    public RadarFine() {}

    public RadarFine(String reference, String nature, String immatriculation,
                     LocalDate notificationDate, Double amount, boolean paid) {
        this.reference = reference;
        this.nature = nature;
        this.immatriculation = immatriculation;
        this.notificationDate = notificationDate;
        this.amount = amount;
        this.paid = paid;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getReference() { return reference; }
    public void setReference(String reference) { this.reference = reference; }

    public String getNature() { return nature; }
    public void setNature(String nature) { this.nature = nature; }

    public String getImmatriculation() { return immatriculation; }
    public void setImmatriculation(String immatriculation) { this.immatriculation = immatriculation; }

    public LocalDate getNotificationDate() { return notificationDate; }
    public void setNotificationDate(LocalDate notificationDate) { this.notificationDate = notificationDate; }

    public Double getAmount() { return amount; }
    public void setAmount(Double amount) { this.amount = amount; }

    public boolean isPaid() { return paid; }
    public void setPaid(boolean paid) { this.paid = paid; }
}