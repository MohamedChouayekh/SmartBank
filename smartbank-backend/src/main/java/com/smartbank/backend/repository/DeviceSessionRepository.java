package com.smartbank.backend.repository;

import com.smartbank.backend.entity.DeviceSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeviceSessionRepository
        extends JpaRepository<DeviceSession, Long> {

    List<DeviceSession>
    findByUserIdAndActiveTrueOrderByLastActivityDesc(
            Long userId
    );

    Optional<DeviceSession>
    findByUserIdAndDeviceIdentifier(
            Long userId,
            String deviceIdentifier
    );
}