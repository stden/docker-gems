package com.example.demo.controller;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.example.demo.model.Product;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/products")
@Tag(name = "Product API", description = "Operations for product management")
public class ProductController {

    private final ConcurrentMap<Long, Product> productDB = new ConcurrentHashMap<>();
    private final AtomicLong idCounter = new AtomicLong(1);

    // Initialize with some sample data
    public ProductController() {
        createSampleProducts();
    }

    private void createSampleProducts() {
        Product p1 = createProduct(idCounter.getAndIncrement(), "Laptop", "High-performance laptop", 
                new BigDecimal("1299.99"), "Electronics", 10);
        Product p2 = createProduct(idCounter.getAndIncrement(), "Smartphone", "Latest smartphone model", 
                new BigDecimal("799.99"), "Electronics", 20);
        Product p3 = createProduct(idCounter.getAndIncrement(), "Desk Chair", "Ergonomic office chair", 
                new BigDecimal("249.99"), "Furniture", 5);
        
        productDB.put(p1.getId(), p1);
        productDB.put(p2.getId(), p2);
        productDB.put(p3.getId(), p3);
    }
    
    private Product createProduct(Long id, String name, String description, BigDecimal price, String category, Integer stockQuantity) {
        Product p = new Product();
        p.setId(id);
        p.setName(name);
        p.setDescription(description);
        p.setPrice(price);
        p.setCategory(category);
        p.setStockQuantity(stockQuantity);
        return p;
    }

    @GetMapping
    @Operation(summary = "Get all products", description = "Returns a list of all available products")
    public List<Product> getAllProducts() {
        return new ArrayList<>(productDB.values());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get product by ID", description = "Returns a product based on its ID")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Product found", 
                     content = @Content(schema = @Schema(implementation = Product.class))),
        @ApiResponse(responseCode = "404", description = "Product not found", 
                     content = @Content)
    })
    public ResponseEntity<Product> getProductById(
            @Parameter(description = "ID of the product to retrieve") 
            @PathVariable Long id) {
        Product product = productDB.get(id);
        if (product == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(product);
    }

    @PostMapping
    @Operation(summary = "Create a new product", description = "Creates and returns a new product")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "201", description = "Product created successfully"),
        @ApiResponse(responseCode = "400", description = "Invalid input")
    })
    public ResponseEntity<Product> createProduct(@Valid @RequestBody Product product) {
        product.setId(idCounter.getAndIncrement());
        productDB.put(product.getId(), product);
        return ResponseEntity.status(HttpStatus.CREATED).body(product);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an existing product", description = "Updates and returns the product")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Product updated successfully"),
        @ApiResponse(responseCode = "404", description = "Product not found"),
        @ApiResponse(responseCode = "400", description = "Invalid input")
    })
    public ResponseEntity<Product> updateProduct(
            @Parameter(description = "ID of the product to update") 
            @PathVariable Long id, 
            @Valid @RequestBody Product product) {
        product.setId(id);
        if (productDB.replace(id, product) == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(product);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a product", description = "Deletes a product by its ID")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "204", description = "Product deleted successfully"),
        @ApiResponse(responseCode = "404", description = "Product not found")
    })
    public ResponseEntity<Void> deleteProduct(
            @Parameter(description = "ID of the product to delete") 
            @PathVariable Long id) {
        if (productDB.remove(id) == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/categories/{category}")
    @Operation(summary = "Get products by category", description = "Returns products for a specific category")
    public List<Product> getProductsByCategory(
            @Parameter(description = "Category to filter by") 
            @PathVariable String category) {
        return productDB.values().stream()
                .filter(p -> category.equalsIgnoreCase(p.getCategory()))
                .toList();
    }
}
