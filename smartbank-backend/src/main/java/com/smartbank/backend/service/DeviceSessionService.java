package com.smartbank.backend.service;

import com.smartbank.backend.entity.DeviceSession;
import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.DeviceSessionRepository;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class DeviceSessionService {

    private static final long HEARTBEAT_TIMEOUT_SECONDS = 60;

    private final DeviceSessionRepository deviceSessionRepository;
    private final UserRepository userRepository;

    public DeviceSessionService(
            DeviceSessionRepository deviceSessionRepository,
            UserRepository userRepository
    ) {
        this.deviceSessionRepository =
                deviceSessionRepository;

        this.userRepository =
                userRepository;
    }

    // =========================================================
    // CREATE / REUSE SESSION
    // =========================================================

    @Transactional
    public DeviceSession createSession(
            Long userId,
            String deviceIdentifier,
            String deviceName,
            String deviceType,
            String browser
    ) {

        User user =
                userRepository.findById(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Utilisateur introuvable."
                                )
                        );

        Optional<DeviceSession> existing =
                deviceSessionRepository
                        .findByUserIdAndDeviceIdentifier(
                                userId,
                                deviceIdentifier
                        );

        DeviceSession session;

        if (existing.isPresent()) {

            session =
                    existing.get();

            session.setDeviceName(
                    deviceName
            );

            session.setDeviceType(
                    deviceType
            );

            session.setBrowser(
                    browser
            );

            session.setActive(
                    true
            );

            session.setCurrent(
                    true
            );

            session.setLastActivity(
                    LocalDateTime.now()
            );

        } else {

            session =
                    new DeviceSession();

            session.setUser(
                    user
            );

            session.setDeviceIdentifier(
                    deviceIdentifier
            );

            session.setDeviceName(
                    deviceName
            );

            session.setDeviceType(
                    deviceType
            );

            session.setBrowser(
                    browser
            );

            session.setActive(
                    true
            );

            session.setCurrent(
                    true
            );

            session.setLastActivity(
                    LocalDateTime.now()
            );
        }

        return deviceSessionRepository.save(
                session
        );
    }

    // =========================================================
    // HEARTBEAT
    // =========================================================

    @Transactional
    public DeviceSession heartbeat(
            Long userId,
            String deviceIdentifier
    ) {

        Optional<DeviceSession> optional =
                deviceSessionRepository
                        .findByUserIdAndDeviceIdentifier(
                                userId,
                                deviceIdentifier
                        );

        if (optional.isEmpty()) {
            throw new SessionInvalidException(
                    "Cette session n'existe plus."
            );
        }

        DeviceSession session =
                optional.get();

        // -----------------------------------------------------
        // SESSION DECONNECTEE MANUELLEMENT
        // -----------------------------------------------------

        if (!session.isActive()) {
            throw new SessionInvalidException(
                    "Cette session a été déconnectée depuis un autre appareil."
            );
        }

        // -----------------------------------------------------
        // SESSION EXPIREE
        // -----------------------------------------------------

        LocalDateTime expirationTime =
                LocalDateTime.now()
                        .minusSeconds(
                                HEARTBEAT_TIMEOUT_SECONDS
                        );

        if (session.getLastActivity() != null
                && session.getLastActivity()
                .isBefore(expirationTime)) {

            session.setActive(false);
            session.setCurrent(false);

            deviceSessionRepository.save(
                    session
            );

            throw new SessionInvalidException(
                    "Cette session a expiré."
            );
        }

        // -----------------------------------------------------
        // ACTUALISER
        // -----------------------------------------------------

        session.setLastActivity(
                LocalDateTime.now()
        );

        session.setActive(
                true
        );

        return deviceSessionRepository.save(
                session
        );
    }

    // =========================================================
    // GET USER SESSIONS
    // =========================================================

    @Transactional
    public List<DeviceSession> getUserSessions(
            Long userId,
            String currentDeviceIdentifier
    ) {

        List<DeviceSession> sessions =
                deviceSessionRepository
                        .findByUserIdAndActiveTrueOrderByLastActivityDesc(
                                userId
                        );

        LocalDateTime expirationTime =
                LocalDateTime.now()
                        .minusSeconds(
                                HEARTBEAT_TIMEOUT_SECONDS
                        );

        boolean changed =
                false;

        for (DeviceSession session : sessions) {

            if (session.getLastActivity() != null
                    && session.getLastActivity()
                    .isBefore(expirationTime)) {

                session.setActive(false);
                session.setCurrent(false);

                changed = true;
            }
        }

        if (changed) {
            deviceSessionRepository.saveAll(
                    sessions
            );
        }

        sessions.removeIf(
                session -> !session.isActive()
        );

        for (DeviceSession session : sessions) {

            boolean current =
                    currentDeviceIdentifier != null
                            && currentDeviceIdentifier.equals(
                            session.getDeviceIdentifier()
                    );

            session.setCurrent(
                    current
            );
        }

        return sessions;
    }

    // =========================================================
    // DISCONNECT ONE SESSION
    // =========================================================

    @Transactional
    public void disconnectSession(
            Long sessionId
    ) {

        DeviceSession session =
                deviceSessionRepository
                        .findById(sessionId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Session introuvable."
                                )
                        );

        session.setActive(false);
        session.setCurrent(false);

        deviceSessionRepository.save(
                session
        );
    }

    // =========================================================
    // DISCONNECT OTHERS
    // =========================================================

    @Transactional
    public void disconnectOtherSessions(
            Long userId,
            Long currentSessionId
    ) {

        List<DeviceSession> sessions =
                deviceSessionRepository
                        .findByUserIdAndActiveTrueOrderByLastActivityDesc(
                                userId
                        );

        for (DeviceSession session : sessions) {

            if (!session.getId().equals(
                    currentSessionId
            )) {

                session.setActive(false);
                session.setCurrent(false);
            }
        }

        deviceSessionRepository.saveAll(
                sessions
        );
    }

    // =========================================================
    // DISCONNECT ALL
    // =========================================================

    @Transactional
    public void disconnectAllSessions(
            Long userId
    ) {

        List<DeviceSession> sessions =
                deviceSessionRepository
                        .findByUserIdAndActiveTrueOrderByLastActivityDesc(
                                userId
                        );

        for (DeviceSession session : sessions) {

            session.setActive(false);
            session.setCurrent(false);
        }

        deviceSessionRepository.saveAll(
                sessions
        );
    }

    // =========================================================
    // SESSION INVALID EXCEPTION
    // =========================================================

    public static class SessionInvalidException
            extends RuntimeException {

        public SessionInvalidException(
                String message
        ) {
            super(message);
        }
    }
}