package com.smartbank.backend.controller;

import com.smartbank.backend.dto.LoginRequest;
import com.smartbank.backend.dto.UserResponse;
import com.smartbank.backend.entity.User;
import com.smartbank.backend.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<UserResponse> createUser(@RequestBody User user) {
        User createdUser = userService.createUser(user);
        return ResponseEntity.ok(new UserResponse(createdUser));
    }

    @PostMapping("/login")
    public ResponseEntity<UserResponse> login(@RequestBody LoginRequest loginRequest) {

        return userService.login(
                        loginRequest.getUsername(),
                        loginRequest.getPassword()
                )
                .map(user -> ResponseEntity.ok(new UserResponse(user)))
                .orElse(ResponseEntity.status(401).build());
    }

    @GetMapping
    public ResponseEntity<List<UserResponse>> getAllUsers() {
        List<UserResponse> users = userService.getAllUsers()
                .stream()
                .map(UserResponse::new)
                .toList();

        return ResponseEntity.ok(users);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getUserById(@PathVariable Long id) {
        return userService.getUserById(id)
                .map(UserResponse::new)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}