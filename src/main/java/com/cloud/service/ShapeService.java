package com.cloud.service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.cloud.repository.ShapeRepository;
import com.cloud.service.dto.ShapeDTO;

@Service
public class ShapeService {
    
    @Autowired
    private ShapeRepository  shapeRepo;


    public List<ShapeDTO> getAllShapes() {
        return shapeRepo.findAll()   .stream().map(ShapeDTO::toDto)
                       .collect(Collectors.toList());
    }


    public ShapeDTO getOneShape(Integer id) {
        return shapeRepo.findById(id).map(ShapeDTO::toDto)
                .orElseThrow(() -> new RuntimeException("No se encontro el shape con ID: " + id));
    }

    public void createShape(ShapeDTO dto){
         shapeRepo.save(dto.toEntity());
    }

    public void deleteShape(Integer id) {
        if (shapeRepo.findById(id).isPresent())
            shapeRepo.deleteById(id);
        else throw new RuntimeException("No se encontro el shape con ID: " + id);
    }

    public void updateShape(ShapeDTO dto) {
        shapeRepo.save(dto.toEntity());
    }


}
