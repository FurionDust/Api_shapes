package com.cloud.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.cloud.service.ShapeService;
import com.cloud.service.dto.ShapeDTO;

@RestController
public class ShapeRestController {

    @Autowired
    private ShapeService shapeService;

    @GetMapping("/shapes")
    public ResponseEntity<List<ShapeDTO>> getAllShapes() {
        return new ResponseEntity<>(shapeService.getAllShapes(), HttpStatus.OK);
    }

    @GetMapping("/shapes/{id}")
    public ResponseEntity<ShapeDTO> getOneShape(@PathVariable("id") Integer id) {
        return new ResponseEntity<>(shapeService.getOneShape(id), HttpStatus.OK);
    }

    @PostMapping("/shapes")
    public ResponseEntity<String> createShape(@RequestBody ShapeDTO shapeDTO) {
        try {
            shapeService.createShape(shapeDTO);
            return new ResponseEntity<>("Shape created successfully", HttpStatus.CREATED);
        } catch (Exception e) {
            return new ResponseEntity<>(e.getMessage(), HttpStatus.BAD_REQUEST);
        }
    }

    @PutMapping("/shapes/{id}")
    public ResponseEntity<String> updateShape(@PathVariable("id") Integer id, @RequestBody ShapeDTO shapeDTO) {
        try {
            
            shapeDTO.setId(id); 
            shapeService.updateShape(shapeDTO);
            return new ResponseEntity<>("Shape updated successfully", HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(e.getMessage(), HttpStatus.BAD_REQUEST);
        }
    }

    
    @DeleteMapping("/shapes/{id}")
    public ResponseEntity<String> deleteShape(@PathVariable("id") Integer id) {
        try {
            shapeService.deleteShape(id);
            return new ResponseEntity<>("Shape deleted successfully", HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(e.getMessage(), HttpStatus.BAD_REQUEST);
        }
    }
}