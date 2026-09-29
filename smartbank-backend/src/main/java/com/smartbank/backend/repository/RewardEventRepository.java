package com.smartbank.backend.repository;

import com.smartbank.backend.entity.RewardEvent;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RewardEventRepository
        extends JpaRepository<RewardEvent, Long> {

    List<RewardEvent>
    findByUserIdOrderByCreatedAtDesc(Long userId);

    List<RewardEvent>
    findTop20ByUserIdOrderByCreatedAtDesc(Long userId);
}