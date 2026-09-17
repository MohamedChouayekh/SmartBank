package com.smartbank.backend.repository;

import com.smartbank.backend.entity.CardUnblockRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CardUnblockRequestRepository
        extends JpaRepository<CardUnblockRequest, Long> {

    List<CardUnblockRequest> findByUser_IdOrderByCreatedAtDesc(
            Long userId
    );

    List<CardUnblockRequest> findAllByOrderByCreatedAtDesc();

    Optional<CardUnblockRequest> findByIdAndUser_Id(
            Long requestId,
            Long userId
    );

    Optional<CardUnblockRequest> findFirstByCard_IdAndStatus(
            Long cardId,
            String status
    );
}