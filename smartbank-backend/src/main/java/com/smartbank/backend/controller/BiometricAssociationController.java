package com.smartbank.backend.controller;

import com.smartbank.backend.entity.BiometricAssociation;
import com.smartbank.backend.service.BiometricAssociationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/biometric")
@CrossOrigin(origins = "*")
public class BiometricAssociationController {

    private final BiometricAssociationService biometricService;

    public BiometricAssociationController(
            BiometricAssociationService biometricService
    ) {
        this.biometricService = biometricService;
    }

    // =========================================================
    // TEST DU CONTROLLER
    // =========================================================
    //
    // Cette route sert uniquement à vérifier que Spring Boot
    // détecte bien BiometricAssociationController.
    //
    // URL :
    // http://localhost:8080/api/biometric/test
    //
    // =========================================================

    @GetMapping("/test")
    public ResponseEntity<Map<String, Object>> test() {

        Map<String, Object> response =
                new HashMap<>();

        response.put(
                "success",
                true
        );

        response.put(
                "message",
                "BiometricAssociationController fonctionne."
        );

        return ResponseEntity.ok(response);
    }

    // =========================================================
    // ACTIVER
    // =========================================================

    @PostMapping("/enable")
    public ResponseEntity<?> enable(
            @RequestBody BiometricRequest request
    ) {
        try {

            if (request == null) {
                Map<String, Object> response =
                        new HashMap<>();

                response.put(
                        "code",
                        "INVALID_REQUEST"
                );

                response.put(
                        "message",
                        "La requête est obligatoire."
                );

                return ResponseEntity
                        .badRequest()
                        .body(response);
            }

            BiometricAssociation association =
                    biometricService.enable(
                            request.userId(),
                            request.deviceIdentifier()
                    );

            return ResponseEntity.ok(
                    buildResponse(
                            association,
                            "Biométrie activée."
                    )
            );

        } catch (IllegalStateException e) {

            Map<String, Object> response =
                    new HashMap<>();

            response.put(
                    "code",
                    "BIOMETRIC_ALREADY_IN_USE"
            );

            response.put(
                    "message",
                    e.getMessage()
            );

            return ResponseEntity
                    .status(HttpStatus.CONFLICT)
                    .body(response);

        } catch (IllegalArgumentException e) {

            Map<String, Object> response =
                    new HashMap<>();

            response.put(
                    "code",
                    "INVALID_REQUEST"
            );

            response.put(
                    "message",
                    e.getMessage()
            );

            return ResponseEntity
                    .badRequest()
                    .body(response);

        } catch (Exception e) {

            e.printStackTrace();

            Map<String, Object> response =
                    new HashMap<>();

            response.put(
                    "code",
                    "BIOMETRIC_ERROR"
            );

            response.put(
                    "message",
                    "Erreur lors de l'activation de la biométrie."
            );

            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(response);
        }
    }

    // =========================================================
    // DÉSACTIVER
    // =========================================================

    @PostMapping("/disable")
    public ResponseEntity<?> disable(
            @RequestBody BiometricRequest request
    ) {
        try {

            if (request == null) {
                Map<String, Object> response =
                        new HashMap<>();

                response.put(
                        "code",
                        "INVALID_REQUEST"
                );

                response.put(
                        "message",
                        "La requête est obligatoire."
                );

                return ResponseEntity
                        .badRequest()
                        .body(response);
            }

            BiometricAssociation association =
                    biometricService.disable(
                            request.userId(),
                            request.deviceIdentifier()
                    );

            return ResponseEntity.ok(
                    buildResponse(
                            association,
                            "Biométrie désactivée."
                    )
            );

        } catch (IllegalStateException e) {

            Map<String, Object> response =
                    new HashMap<>();

            response.put(
                    "code",
                    "BIOMETRIC_NOT_OWNER"
            );

            response.put(
                    "message",
                    e.getMessage()
            );

            return ResponseEntity
                    .status(HttpStatus.FORBIDDEN)
                    .body(response);

        } catch (IllegalArgumentException e) {

            Map<String, Object> response =
                    new HashMap<>();

            response.put(
                    "code",
                    "INVALID_REQUEST"
            );

            response.put(
                    "message",
                    e.getMessage()
            );

            return ResponseEntity
                    .badRequest()
                    .body(response);

        } catch (Exception e) {

            e.printStackTrace();

            Map<String, Object> response =
                    new HashMap<>();

            response.put(
                    "code",
                    "BIOMETRIC_ERROR"
            );

            response.put(
                    "message",
                    "Erreur lors de la désactivation de la biométrie."
            );

            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(response);
        }
    }

    // =========================================================
    // ÉTAT PAR APPAREIL
    // =========================================================

    @GetMapping("/device")
    public ResponseEntity<Map<String, Object>> getDevice(
            @RequestParam String deviceIdentifier
    ) {
        return ResponseEntity.ok(
                biometricService.getByDevice(
                        deviceIdentifier
                )
        );
    }

    // =========================================================
    // ÉTAT PAR COMPTE
    // =========================================================

    @GetMapping("/user/{userId}")
    public ResponseEntity<Map<String, Object>> getUser(
            @PathVariable Long userId
    ) {
        return ResponseEntity.ok(
                biometricService.getByUser(userId)
        );
    }

    // =========================================================
    // RESPONSE
    // =========================================================

    private Map<String, Object> buildResponse(
            BiometricAssociation association,
            String message
    ) {
        Map<String, Object> response =
                new HashMap<>();

        response.put(
                "id",
                association.getId()
        );

        response.put(
                "userId",
                association.getUser().getId()
        );

        response.put(
                "deviceIdentifier",
                association.getDeviceIdentifier()
        );

        response.put(
                "associated",
                true
        );

        response.put(
                "enabled",
                association.isEnabled()
        );

        response.put(
                "message",
                message
        );

        return response;
    }

    // =========================================================
    // REQUEST
    // =========================================================

    public record BiometricRequest(
            Long userId,
            String deviceIdentifier
    ) {
    }
}