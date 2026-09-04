package com.smartbank.backend.exception;

public class BiometricAlreadyAssociatedException extends RuntimeException {

    public BiometricAlreadyAssociatedException(String message) {
        super(message);
    }
}