package com.smartbank.backend.controller;

import com.smartbank.backend.dto.NotificationResponse;
import com.smartbank.backend.entity.Notification;
import com.smartbank.backend.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    // =========================================================
    // LISTER LES NOTIFICATIONS D'UN UTILISATEUR
    // =========================================================

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<NotificationResponse>> getByUser(
            @PathVariable Long userId) {

        List<Notification> notifications =
                notificationService.getNotifications(userId);

        List<NotificationResponse> response = notifications.stream()
                .map(NotificationResponse::new)
                .toList();

        return ResponseEntity.ok(response);
    }

    // =========================================================
    // MARQUER COMME LUE
    // =========================================================

    @PutMapping("/{notificationId}/read")
    public ResponseEntity<?> markAsRead(@PathVariable Long notificationId) {
        try {
            notificationService.markAsRead(notificationId);
            return ResponseEntity.ok(Map.of("message", "Notification marquée comme lue."));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }
}