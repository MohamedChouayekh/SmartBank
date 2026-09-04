package com.smartbank.backend.service;

import com.smartbank.backend.entity.Notification;
import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.NotificationRepository;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public NotificationService(
            NotificationRepository notificationRepository,
            UserRepository userRepository) {

        this.notificationRepository =
                notificationRepository;

        this.userRepository =
                userRepository;
    }

    // =========================================================
    // NOTIFICATION TRANSFERT SIMPLE
    // =========================================================

    public void notifyTransfer(
            Long userId,
            String title,
            String message) {

        createNotification(
                userId,
                "TRANSFER",
                title,
                message,
                null,
                null,
                null,
                null,
                null
        );
    }

    // =========================================================
    // NOTIFICATION TRANSFERT DÉTAILLÉE
    // =========================================================

    public void notifyTransferDetailed(
            Long userId,
            String title,
            String message,
            String senderName,
            String senderAccountNumber,
            BigDecimal amount,
            String sourceAccountType,
            String destinationAccountType) {

        createNotification(
                userId,
                "TRANSFER",
                title,
                message,
                senderName,
                senderAccountNumber,
                amount,
                sourceAccountType,
                destinationAccountType
        );
    }

    // =========================================================
    // NOTIFICATION PAIEMENT
    // =========================================================

    public void notifyPayment(
            Long userId,
            String title,
            String message) {

        createNotification(
                userId,
                "PAYMENT",
                title,
                message,
                null,
                null,
                null,
                null,
                null
        );
    }

    // =========================================================
    // CRÉATION
    // =========================================================

    private void createNotification(
            Long userId,
            String type,
            String title,
            String message,
            String senderName,
            String senderAccountNumber,
            BigDecimal amount,
            String sourceAccountType,
            String destinationAccountType) {

        User user =
                userRepository.findById(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Utilisateur introuvable avec id : "
                                                + userId
                                )
                        );

        Notification notification =
                new Notification();

        notification.setUser(user);

        notification.setType(type);

        notification.setTitle(title);

        notification.setMessage(message);

        notification.setSenderName(senderName);

        notification.setSenderAccountNumber(
                senderAccountNumber
        );

        notification.setAmount(amount);

        notification.setSourceAccountType(
                sourceAccountType
        );

        notification.setDestinationAccountType(
                destinationAccountType
        );

        notification.setRead(false);

        notificationRepository.save(
                notification
        );
    }

    // =========================================================
    // LISTER
    // =========================================================

    public List<Notification> getNotifications(
            Long userId) {

        return notificationRepository
                .findByUserIdOrderByCreatedAtDesc(
                        userId
                );
    }

    // =========================================================
    // LIRE
    // =========================================================

    public void markAsRead(
            Long notificationId) {

        Notification notification =
                notificationRepository
                        .findById(notificationId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Notification introuvable."
                                )
                        );

        notification.setRead(true);

        notificationRepository.save(
                notification
        );
    }
}