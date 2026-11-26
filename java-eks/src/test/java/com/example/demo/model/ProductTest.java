package com.example.demo.model;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

public class ProductTest {

    @Test
    void settersAndGetters_shouldWork() {
        Product product = new Product();
        
        Long id = 1L;
        String name = "Test Product";
        String description = "Test Description";
        BigDecimal price = new BigDecimal("99.99");
        String category = "Test Category";
        Integer stockQuantity = 50;
        
        product.setId(id);
        product.setName(name);
        product.setDescription(description);
        product.setPrice(price);
        product.setCategory(category);
        product.setStockQuantity(stockQuantity);
        
        assertEquals(id, product.getId());
        assertEquals(name, product.getName());
        assertEquals(description, product.getDescription());
        assertEquals(price, product.getPrice());
        assertEquals(category, product.getCategory());
        assertEquals(stockQuantity, product.getStockQuantity());
    }
    
    @Test
    void productNoArgsConstructor_shouldCreateEmptyProduct() {
        Product product = new Product();
        
        assertNull(product.getId());
        assertNull(product.getName());
        assertNull(product.getDescription());
        assertNull(product.getPrice());
        assertNull(product.getCategory());
        assertNull(product.getStockQuantity());
    }
    
    @Test
    void toString_shouldIncludeFields() {
        Product product = new Product();
        product.setId(1L);
        product.setName("Test");
        product.setDescription("Desc");
        product.setPrice(new BigDecimal("10.00"));
        product.setCategory("Cat");
        product.setStockQuantity(5);
        
        String toString = product.toString();
        
        assertTrue(toString.contains("id=" + product.getId()));
        assertTrue(toString.contains("name=" + product.getName()));
        assertTrue(toString.contains("description=" + product.getDescription()));
        assertTrue(toString.contains("price=" + product.getPrice()));
        assertTrue(toString.contains("category=" + product.getCategory()));
        assertTrue(toString.contains("stockQuantity=" + product.getStockQuantity()));
    }
    
    @Test
    void equals_withSameValues_shouldBeEqual() {
        Product product1 = new Product();
        product1.setId(1L);
        product1.setName("Test");
        product1.setDescription("Desc");
        product1.setPrice(new BigDecimal("10.00"));
        product1.setCategory("Cat");
        product1.setStockQuantity(5);
        
        Product product2 = new Product();
        product2.setId(1L);
        product2.setName("Test");
        product2.setDescription("Desc");
        product2.setPrice(new BigDecimal("10.00"));
        product2.setCategory("Cat");
        product2.setStockQuantity(5);
        
        assertEquals(product1, product2);
        assertEquals(product1.hashCode(), product2.hashCode());
    }
    
    @Test
    void equals_withDifferentValues_shouldNotBeEqual() {
        Product product1 = new Product();
        product1.setId(1L);
        product1.setName("Test");
        
        Product product2 = new Product();
        product2.setId(2L);
        product2.setName("Test");
        
        assertNotEquals(product1, product2);
    }
    
    @Test
    void equals_withNull_shouldNotBeEqual() {
        Product product = new Product();
        product.setId(1L);
        
        assertNotEquals(product, null);
    }
    
    @Test
    void equals_withDifferentClass_shouldNotBeEqual() {
        Product product = new Product();
        product.setId(1L);
        
        assertNotEquals(product, "string");
    }
    
    @Test
    void equals_withSameInstance_shouldBeEqual() {
        Product product = new Product();
        product.setId(1L);
        
        assertEquals(product, product);
    }
}
