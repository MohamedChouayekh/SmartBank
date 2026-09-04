package com.smartbank.backend.controller;

import com.smartbank.backend.dto.NotificationPreferenceRequest;
import com.smartbank.backend.dto.NotificationPreferenceResponse;
import com.smartbank.backend.service.NotificationPreferenceService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notification-preferences")
public class NotificationPreferenceController {

    private final NotificationPreferenceService preferenceService;

    // =========================================================
    // CONSTRUCTEUR
    // =========================================================

    public NotificationPreferenceController(
            NotificationPreferenceService preferenceService) {

        this.preferenceService = preferenceService;
    }

    // =========================================================
    // RÉCUPÉRER LES PRÉFÉRENCES
    // =========================================================

    @GetMapping("/{userId}")
    public ResponseEntity<NotificationPreferenceResponse>
    getPreferences(
            @PathVariable Long userId) {

        return ResponseEntity.ok(
                preferenceService.getPreferences(userId)
        );
    }

    // =========================================================
    // MODIFIER LES PRÉFÉRENCES
    // =========================================================

    @PutMapping("/{userId}")
    public ResponseEntity<NotificationPreferenceResponse>
    updatePreferences(
            @PathVariable Long userId,
            @RequestBody NotificationPreferenceRequest request) {

        return ResponseEntity.ok(
                preferenceService.updatePreferences(
                        userId,
                        request
                )
        );
    }
}