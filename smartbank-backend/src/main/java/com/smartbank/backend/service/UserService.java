package com.smartbank.backend.service;

import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.BiometricAssociationRepository;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final BiometricAssociationRepository biometricAssociationRepository;

    public UserService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            BiometricAssociationRepository biometricAssociationRepository
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.biometricAssociationRepository =
                biometricAssociationRepository;
    }

    // =========================================================
    // CRÉER UN UTILISATEUR
    // =========================================================

    public User createUser(User user) {
        user.setPassword(
                passwordEncoder.encode(user.getPassword())
        );

        return userRepository.save(user);
    }

    // =========================================================
    // RÉCUPÉRER TOUS LES UTILISATEURS
    // =========================================================

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    // =========================================================
    // RÉCUPÉRER PAR ID
    // =========================================================

    public Optional<User> getUserById(Long id) {
        return userRepository.findById(id);
    }

    // =========================================================
    // RÉCUPÉRER PAR USERNAME
    // =========================================================

    public Optional<User> getUserByUsername(
            String username
    ) {
        return userRepository.findByUsername(username);
    }

    // =========================================================
    // RÉCUPÉRER PAR EMAIL
    // =========================================================

    public Optional<User> getUserByEmail(
            String email
    ) {
        return userRepository.findByEmail(email);
    }

    // =========================================================
    // VÉRIFIER USERNAME
    // =========================================================

    public boolean existsByUsername(
            String username
    ) {
        return userRepository.existsByUsername(username);
    }

    // =========================================================
    // VÉRIFIER EMAIL
    // =========================================================

    public boolean existsByEmail(
            String email
    ) {
        return userRepository.existsByEmail(email);
    }

    // =========================================================
    // SUPPRIMER UN UTILISATEUR
    // =========================================================
    //
    // IMPORTANT :
    //
    // 1. On supprime d'abord les associations biométriques.
    // 2. Ensuite on supprime le compte.
    //
    // Cela permet de libérer le téléphone pour qu'un autre
    // compte puisse utiliser la biométrie.
    //
    // Exemple :
    //
    // med123456
    //    ↓
    // device X
    //    ↓
    // compte supprimé
    //    ↓
    // association supprimée
    //    ↓
    // device X devient disponible
    //
    // =========================================================

    public void deleteUser(Long id) {

        // Vérifier que l'utilisateur existe.
        if (!userRepository.existsById(id)) {
            return;
        }

        // Supprimer toutes les associations biométriques
        // appartenant à cet utilisateur.
        biometricAssociationRepository.deleteByUser_Id(id);

        // Enfin supprimer le compte.
        userRepository.deleteById(id);
    }

    // =========================================================
    // LOGIN
    // =========================================================

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

        // Compte désactivé.
        if (!user.isEnabled()) {
            return Optional.empty();
        }

        // Vérification du mot de passe.
        if (!passwordEncoder.matches(
                password,
                user.getPassword()
        )) {
            return Optional.empty();
        }

        return Optional.of(user);
    }
}