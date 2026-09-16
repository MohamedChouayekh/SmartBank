        package com.smartbank.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String senderEmail;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendOtpEmail(String email, String otp) {

        String text =
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
                        + "L'équipe SmartBank";

        try {

            SimpleMailMessage message = new SimpleMailMessage();

            message.setFrom(senderEmail);
            message.setTo(email);
            message.setSubject("SmartBank - Code de vérification");
            message.setText(text);

            mailSender.send(message);

        } catch (Exception e) {

            throw new IllegalStateException(
                    "Impossible d'envoyer l'email OTP.",
                    e
            );
        }
    }
}
