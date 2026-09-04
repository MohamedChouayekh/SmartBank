package com.smartbank.backend.dto;

import com.smartbank.backend.entity.Notification;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class NotificationResponse {

    private Long id;

    private String type;

    private String title;

    private String message;

    private boolean read;

    private LocalDateTime createdAt;

    private String senderName;

    private String senderAccountNumber;

    private BigDecimal amount;

    private String sourceAccountType;

    private String destinationAccountType;

    public NotificationResponse(
            Notification notification) {

        this.id =
                notification.getId();

        this.type =
                notification.getType();

        this.title =
                notification.getTitle();

        this.message =
                notification.getMessage();

        this.read =
                notification.isRead();

        this.createdAt =
                notification.getCreatedAt();

        this.senderName =
                notification.getSenderName();

        this.senderAccountNumber =
                notification.getSenderAccountNumber();

        this.amount =
                notification.getAmount();

        this.sourceAccountType =
                notification.getSourceAccountType();

        this.destinationAccountType =
                notification.getDestinationAccountType();
    }

    public Long getId() {
        return id;
    }

    public String getType() {
        return type;
    }

    public String getTitle() {
        return title;
    }

    public String getMessage() {
        return message;
    }

    public boolean isRead() {
        return read;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public String getSenderName() {
        return senderName;
    }

    public String getSenderAccountNumber() {
        return senderAccountNumber;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public String getSourceAccountType() {
        return sourceAccountType;
    }

    public String getDestinationAccountType() {
        return destinationAccountType;
    }
}