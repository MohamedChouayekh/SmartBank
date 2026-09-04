package com.smartbank.backend.controller;

import com.smartbank.backend.entity.DeviceSession;
import com.smartbank.backend.service.DeviceSessionService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/device-sessions")
public class DeviceSessionController {

    private final DeviceSessionService deviceSessionService;

    public DeviceSessionController(
            DeviceSessionService deviceSessionService
    ) {
        this.deviceSessionService =
                deviceSessionService;
    }

    // =========================================================
    // GET USER SESSIONS
    // =========================================================

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<DeviceSession>>
    getUserSessions(
            @PathVariable Long userId,
            @RequestParam(
                    required = false
            )
            String currentDeviceIdentifier
    ) {

        return ResponseEntity.ok(
                deviceSessionService.getUserSessions(
                        userId,
                        currentDeviceIdentifier
                )
        );
    }

    // =========================================================
    // CREATE SESSION
    // =========================================================

    @PostMapping
    public ResponseEntity<DeviceSession>
    createSession(
            @RequestBody DeviceSessionRequest request
    ) {

        DeviceSession session =
                deviceSessionService.createSession(
                        request.getUserId(),
                        request.getDeviceIdentifier(),
                        request.getDeviceName(),
                        request.getDeviceType(),
                        request.getBrowser()
                );

        return ResponseEntity.ok(
                session
        );
    }

    // =========================================================
    // HEARTBEAT
    // =========================================================

    @PostMapping("/heartbeat")
    public ResponseEntity<?> heartbeat(
            @RequestBody HeartbeatRequest request
    ) {

        try {

            DeviceSession session =
                    deviceSessionService.heartbeat(
                            request.getUserId(),
                            request.getDeviceIdentifier()
                    );

            return ResponseEntity.ok(
                    session
            );

        } catch (
                DeviceSessionService.SessionInvalidException e
        ) {

            Map<String, Object> response =
                    new HashMap<>();

            response.put(
                    "active",
                    false
            );

            response.put(
                    "sessionInvalid",
                    true
            );

            response.put(
                    "message",
                    e.getMessage()
            );

            return ResponseEntity
                    .status(
                            HttpStatus.UNAUTHORIZED
                    )
                    .body(
                            response
                    );
        }
    }

    // =========================================================
    // DISCONNECT ONE
    // =========================================================

    @DeleteMapping("/{sessionId}")
    public ResponseEntity<?> disconnectSession(
            @PathVariable Long sessionId
    ) {

        deviceSessionService.disconnectSession(
                sessionId
        );

        return ResponseEntity.ok(
                Map.of(
                        "success",
                        true,
                        "message",
                        "Session déconnectée."
                )
        );
    }

    // =========================================================
    // DISCONNECT OTHERS
    // =========================================================

    @PostMapping("/disconnect-others")
    public ResponseEntity<?> disconnectOtherSessions(
            @RequestBody
            DisconnectOthersRequest request
    ) {

        deviceSessionService
                .disconnectOtherSessions(
                        request.getUserId(),
                        request.getCurrentSessionId()
                );

        return ResponseEntity.ok(
                Map.of(
                        "success",
                        true,
                        "message",
                        "Les autres sessions ont été déconnectées."
                )
        );
    }

    // =========================================================
    // DISCONNECT ALL
    // =========================================================

    @PostMapping("/disconnect-all")
    public ResponseEntity<?> disconnectAllSessions(
            @RequestBody UserIdRequest request
    ) {

        deviceSessionService
                .disconnectAllSessions(
                        request.getUserId()
                );

        return ResponseEntity.ok(
                Map.of(
                        "success",
                        true,
                        "message",
                        "Toutes les sessions ont été déconnectées."
                )
        );
    }

    // =========================================================
    // DTO SESSION
    // =========================================================

    public static class DeviceSessionRequest {

        private Long userId;
        private String deviceIdentifier;
        private String deviceName;
        private String deviceType;
        private String browser;

        public Long getUserId() {
            return userId;
        }

        public void setUserId(Long userId) {
            this.userId = userId;
        }

        public String getDeviceIdentifier() {
            return deviceIdentifier;
        }

        public void setDeviceIdentifier(
                String deviceIdentifier
        ) {
            this.deviceIdentifier =
                    deviceIdentifier;
        }

        public String getDeviceName() {
            return deviceName;
        }

        public void setDeviceName(
                String deviceName
        ) {
            this.deviceName =
                    deviceName;
        }

        public String getDeviceType() {
            return deviceType;
        }

        public void setDeviceType(
                String deviceType
        ) {
            this.deviceType =
                    deviceType;
        }

        public String getBrowser() {
            return browser;
        }

        public void setBrowser(
                String browser
        ) {
            this.browser =
                    browser;
        }
    }

    // =========================================================
    // DTO HEARTBEAT
    // =========================================================

    public static class HeartbeatRequest {

        private Long userId;
        private String deviceIdentifier;

        public Long getUserId() {
            return userId;
        }

        public void setUserId(
                Long userId
        ) {
            this.userId =
                    userId;
        }

        public String getDeviceIdentifier() {
            return deviceIdentifier;
        }

        public void setDeviceIdentifier(
                String deviceIdentifier
        ) {
            this.deviceIdentifier =
                    deviceIdentifier;
        }
    }

    // =========================================================
    // DTO DISCONNECT OTHERS
    // =========================================================

    public static class DisconnectOthersRequest {

        private Long userId;
        private Long currentSessionId;

        public Long getUserId() {
            return userId;
        }

        public void setUserId(
                Long userId
        ) {
            this.userId =
                    userId;
        }

        public Long getCurrentSessionId() {
            return currentSessionId;
        }

        public void setCurrentSessionId(
                Long currentSessionId
        ) {
            this.currentSessionId =
                    currentSessionId;
        }
    }

    // =========================================================
    // DTO USER ID
    // =========================================================

    public static class UserIdRequest {

        private Long userId;

        public Long getUserId() {
            return userId;
        }

        public void setUserId(
                Long userId
        ) {
            this.userId =
                    userId;
        }
    }
}