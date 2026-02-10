package com.cloud.repository.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
@Entity
@Table(name = "shapes")
public class Shape {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "shape_seq")
    @SequenceGenerator(name = "shape_seq", sequenceName = "shape_sequence", allocationSize = 1)
    private Integer id;
    private Integer sides;
    private String color;
    private String name;

}
