package com.cloud.service.dto;


import com.cloud.repository.model.Shape;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShapeDTO {
    private Integer id;
    private Integer sides;
    private String color;
    private String name;

    
    public Shape toEntity() {
        return Shape.builder()
        .id(this.getId())
        .sides(this.getSides())
        .color(this.getColor())
        .name(this.getName())
        .build();
    

    }

    /* 
    public static Shape toEntity(ShapeDTO shapeDTO) {
        return Shape.builder()
        .id(shapeDTO.getId())
        .sides(shapeDTO.getSides())
        .color(shapeDTO.getColor())
        .name(shapeDTO.getName())
        .build();
    

    } */

    public static ShapeDTO toDto (Shape shape){
        return ShapeDTO.builder()
        .id(shape.getId())
        .sides(shape.getSides())
        .color(shape.getColor())
        .name(shape.getName())
        .build();
        }


}