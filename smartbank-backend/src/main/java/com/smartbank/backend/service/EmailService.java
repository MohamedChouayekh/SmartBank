package com.smartbank.backend.service;

import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendOtpEmail(String email, String otp) {

        SimpleMailMessage message =
                new SimpleMailMessage();

        message.setTo(email);

        message.setSubject(
                "SmartBank - Code de vérification"
        );

        message.setText(
                "Bonjour,\n\n"
                        + "Vous avez demandé la réinitialisation "
                        + "de votre mot de passe SmartBank.\n\n"
                        + "Votre code de vérification est : "
                        + otp
                        + "\n\n"
                        + "Ce code est valable pendant 5 minutes.\n\n"
                        + "Si vous n'êtes pas à l'origine de cette demande, "
                        + "ignorez simplement cet e-mail.\n\n"
                        + "Cordialement,\n"
                        + "L'équipe SmartBank"
        );

        mailSender.send(message);
    }
}