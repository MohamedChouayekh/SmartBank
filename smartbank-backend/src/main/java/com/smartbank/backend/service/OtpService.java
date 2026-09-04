package com.smartbank.backend.service;

import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OtpService {

    private final SecureRandom secureRandom = new SecureRandom();

    private final Map<String, OtpData> otpStorage =
            new ConcurrentHashMap<>();

    private static final int OTP_EXPIRATION_MINUTES = 5;

    public String generateOtp(String email) {

        String otp = String.format(
                "%06d",
                secureRandom.nextInt(1_000_000)
        );

        LocalDateTime expiration =
                LocalDateTime.now()
                        .plusMinutes(OTP_EXPIRATION_MINUTES);

        otpStorage.put(
                email.toLowerCase(),
                new OtpData(otp, expiration)
        );

        return otp;
    }

    public boolean verifyOtp(String email, String otp) {

        String normalizedEmail =
                email.trim().toLowerCase();

        OtpData otpData =
                otpStorage.get(normalizedEmail);

        if (otpData == null) {
            return false;
        }

        if (LocalDateTime.now()
                .isAfter(otpData.expiration)) {

            otpStorage.remove(normalizedEmail);
            return false;
        }

        if (!otpData.otp.equals(otp)) {
            return false;
        }

        return true;
    }

    public void removeOtp(String email) {
        otpStorage.remove(
                email.trim().toLowerCase()
        );
    }

    private static class OtpData {

        private final String otp;
        private final LocalDateTime expiration;

        public OtpData(
                String otp,
                LocalDateTime expiration
        ) {
            this.otp = otp;
            this.expiration = expiration;
        }
    }
}