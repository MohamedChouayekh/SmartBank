package com.smartbank.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class EmailService {

    @Value("${SENDGRID_API_KEY:}")
    private String apiKey;

    @Value("${MAIL_USERNAME:}")
    private String senderEmail;

    private final RestTemplate restTemplate = new RestTemplate();

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
            String url = "https://api.sendgrid.com/v3/mail/send";

            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + apiKey);
            headers.setContentType(MediaType.APPLICATION_JSON);

            String escapedText = text.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");

            String jsonBody = "{"
                    + "\"personalizations\":[{"
                    + "\"to\":[{\"email\":\"" + email + "\"}]"
                    + "}],"
                    + "\"from\":{\"email\":\"" + senderEmail + "\",\"name\":\"SmartBank\"},"
                    + "\"subject\":\"SmartBank - Code de vérification\","
                    + "\"content\":[{\"type\":\"text/plain\",\"value\":\"" + escapedText + "\"}]"
                    + "}";

            HttpEntity<String> request = new HttpEntity<>(jsonBody, headers);

            restTemplate.exchange(url, HttpMethod.POST, request, String.class);

        } catch (Exception e) {
            throw new IllegalStateException(
                    "Impossible d'envoyer l'email OTP.",
                    e
            );
        }
    }
}