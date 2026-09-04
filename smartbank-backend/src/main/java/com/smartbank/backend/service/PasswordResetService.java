package com.smartbank.backend.service;

import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class PasswordResetService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final OtpService otpService;
    private final EmailService emailService;

    public PasswordResetService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            OtpService otpService,
            EmailService emailService
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.otpService = otpService;
        this.emailService = emailService;
    }

    public boolean sendOtp(String email) {

        Optional<User> userOptional =
                userRepository.findByEmail(
                        email.trim().toLowerCase()
                );

        if (userOptional.isEmpty()) {
            return false;
        }

        User user = userOptional.get();

        if (!user.isEnabled()) {
            return false;
        }

        String otp =
                otpService.generateOtp(user.getEmail());

        emailService.sendOtpEmail(
                user.getEmail(),
                otp
        );

        return true;
    }

    public boolean verifyOtp(
            String email,
            String otp
    ) {

        Optional<User> userOptional =
                userRepository.findByEmail(
                        email.trim().toLowerCase()
                );

        if (userOptional.isEmpty()) {
            return false;
        }

        return otpService.verifyOtp(
                email,
                otp
        );
    }

    public boolean resetPassword(
            String email,
            String otp,
            String newPassword
    ) {

        Optional<User> userOptional =
                userRepository.findByEmail(
                        email.trim().toLowerCase()
                );

        if (userOptional.isEmpty()) {
            return false;
        }

        boolean validOtp =
                otpService.verifyOtp(
                        email,
                        otp
                );

        if (!validOtp) {
            return false;
        }

        User user = userOptional.get();

        user.setPassword(
                passwordEncoder.encode(newPassword)
        );

        userRepository.save(user);

        otpService.removeOtp(email);

        return true;
    }
}