package com.cloud.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.cloud.repository.model.Shape;

@Transactional
@Repository
public interface ShapeRepository extends JpaRepository<Shape,Integer> {
    
    
}
