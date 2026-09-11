package com.smartbank.backend.repository;

import com.smartbank.backend.entity.Card;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CardRepository extends JpaRepository<Card, Long> {

    List<Card> findByAccount_Id(Long accountId);

    List<Card> findByAccount_User_Id(Long userId);

    Optional<Card> findByIdAndAccount_User_Id(
            Long cardId,
            Long userId
    );

    boolean existsByLastFourDigitsAndAccount_Id(
            String lastFourDigits,
            Long accountId
    );
}