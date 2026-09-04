package com.smartbank.backend.repository;

import com.smartbank.backend.entity.NotificationPreference;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface NotificationPreferenceRepository
        extends JpaRepository<NotificationPreference, Long> {

    Optional<NotificationPreference> findByUserId(Long userId);
}