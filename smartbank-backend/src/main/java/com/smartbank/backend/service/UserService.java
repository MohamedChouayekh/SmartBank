        package com.smartbank.backend.service;

import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.BiometricAssociationRepository;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final BiometricAssociationRepository biometricAssociationRepository;
    private final AccountService accountService;
    private final CardService cardService;

    public UserService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            BiometricAssociationRepository biometricAssociationRepository,
            AccountService accountService,
            CardService cardService
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.biometricAssociationRepository =
                biometricAssociationRepository;
        this.accountService = accountService;
        this.cardService = cardService;
    }

    @Transactional
    public User createUser(User user) {

        user.setPassword(
                passwordEncoder.encode(user.getPassword())
        );

        if (user.getRole() == null ||
                user.getRole().trim().isEmpty()) {
            user.setRole("CLIENT");
        }

        user.setRole(
                user.getRole().trim().toUpperCase()
        );

        user.setEnabled(true);

        User createdUser =
                userRepository.save(user);

        accountService.createAccount(
                createdUser.getId(),
                "CURRENT"
        );

        accountService.createAccount(
                createdUser.getId(),
                "SAVINGS"
        );

        cardService.assignCard(
                createdUser.getId(),
                "VISA"
        );

        return createdUser;
    }

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public Optional<User> getUserById(Long id) {
        return userRepository.findById(id);
    }

    public Optional<User> getUserByUsername(
            String username
    ) {
        return userRepository.findByUsername(username);
    }

    public Optional<User> getUserByEmail(
            String email
    ) {
        return userRepository.findByEmail(email);
    }

    public boolean existsByUsername(
            String username
    ) {
        return userRepository.existsByUsername(username);
    }

    public boolean existsByEmail(
            String email
    ) {
        return userRepository.existsByEmail(email);
    }

    public void deleteUser(Long id) {

        if (!userRepository.existsById(id)) {
            return;
        }

        biometricAssociationRepository.deleteByUser_Id(id);

        userRepository.deleteById(id);
    }

    public Optional<User> login(
            String username,
            String password
    ) {

        Optional<User> userOptional =
                userRepository.findByUsername(username);

        if (userOptional.isEmpty()) {
            return Optional.empty();
        }

        User user = userOptional.get();

        if (!user.isEnabled()) {
            return Optional.empty();
        }

        if (!passwordEncoder.matches(
                password,
                user.getPassword()
        )) {
            return Optional.empty();
        }

        return Optional.of(user);
    }
}
