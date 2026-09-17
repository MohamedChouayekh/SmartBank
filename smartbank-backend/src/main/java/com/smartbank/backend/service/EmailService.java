package com.smartbank.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Base64;

@Service
public class EmailService {

    @Value("${MAILJET_API_KEY:}")
    private String apiKey;

    @Value("${MAILJET_SECRET_KEY:}")
    private String secretKey;

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
            String url = "https://api.mailjet.com/v3.1/send";

            String auth = apiKey + ":" + secretKey;
            String encodedAuth = Base64.getEncoder().encodeToString(auth.getBytes());

            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Basic " + encodedAuth);
            headers.setContentType(MediaType.APPLICATION_JSON);

            String escapedText = text.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");

            String jsonBody = "{"
                    + "\"Messages\":[{"
                    + "\"From\":{\"Email\":\"" + senderEmail + "\",\"Name\":\"SmartBank\"},"
                    + "\"To\":[{\"Email\":\"" + email + "\"}],"
                    + "\"Subject\":\"SmartBank - Code de vérification\","
                    + "\"TextPart\":\"" + escapedText + "\""
                    + "}]"
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