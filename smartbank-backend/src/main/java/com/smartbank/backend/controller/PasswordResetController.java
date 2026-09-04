package com.smartbank.backend.controller;

import com.smartbank.backend.dto.ForgotPasswordRequest;
import com.smartbank.backend.dto.ResetPasswordRequest;
import com.smartbank.backend.dto.VerifyOtpRequest;
import com.smartbank.backend.service.PasswordResetService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/password")
public class PasswordResetController {

    private final PasswordResetService passwordResetService;

    public PasswordResetController(
            PasswordResetService passwordResetService
    ) {
        this.passwordResetService = passwordResetService;
    }

    // =========================================================
    // ENVOYER OTP
    // =========================================================

    @PostMapping("/forgot")
    public ResponseEntity<?> forgotPassword(
            @RequestBody ForgotPasswordRequest request
    ) {

        if (request.getEmail() == null ||
                request.getEmail().trim().isEmpty()) {

            return ResponseEntity.badRequest()
                    .body("L'adresse email est obligatoire.");
        }

        boolean sent =
                passwordResetService.sendOtp(
                        request.getEmail()
                );

        if (!sent) {
            return ResponseEntity.status(404)
                    .body("Aucun compte trouvé avec cette adresse email.");
        }

        return ResponseEntity.ok(
                "Code de vérification envoyé par email."
        );
    }

    // =========================================================
    // VERIFIER OTP
    // =========================================================

    @PostMapping("/verify-otp")
    public ResponseEntity<?> verifyOtp(
            @RequestBody VerifyOtpRequest request
    ) {

        if (request.getEmail() == null ||
                request.getOtp() == null) {

            return ResponseEntity.badRequest()
                    .body("Email et code OTP obligatoires.");
        }

        boolean valid =
                passwordResetService.verifyOtp(
                        request.getEmail(),
                        request.getOtp()
                );

        if (!valid) {
            return ResponseEntity.status(401)
                    .body("Code de vérification incorrect ou expiré.");
        }

        return ResponseEntity.ok(
                "Code de vérification valide."
        );
    }

    // =========================================================
    // REINITIALISER MOT DE PASSE
    // =========================================================

    @PostMapping("/reset")
    public ResponseEntity<?> resetPassword(
            @RequestBody ResetPasswordRequest request
    ) {

        if (request.getEmail() == null ||
                request.getOtp() == null ||
                request.getNewPassword() == null) {

            return ResponseEntity.badRequest()
                    .body(
                            "Email, OTP et nouveau mot de passe obligatoires."
                    );
        }

        boolean reset =
                passwordResetService.resetPassword(
                        request.getEmail(),
                        request.getOtp(),
                        request.getNewPassword()
                );

        if (!reset) {
            return ResponseEntity.status(401)
                    .body(
                            "Impossible de réinitialiser le mot de passe. "
                                    + "OTP incorrect ou expiré."
                    );
        }

        return ResponseEntity.ok(
                "Mot de passe modifié avec succès."
        );
    }
}