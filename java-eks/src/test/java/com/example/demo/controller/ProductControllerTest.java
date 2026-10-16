package com.example.demo.controller;

import com.example.demo.model.Product;
import tools.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(ProductController.class)
public class ProductControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private Product testProduct;

    @BeforeEach
    void setUp() {
        testProduct = new Product();
        testProduct.setName("Test Product");
        testProduct.setDescription("Test Description");
        testProduct.setPrice(new BigDecimal("99.99"));
        testProduct.setCategory("Test Category");
        testProduct.setStockQuantity(50);
    }

    @Test
    void getAllProducts_shouldReturnAllProducts() throws Exception {
        mockMvc.perform(get("/api/products"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(3))))
                .andExpect(jsonPath("$[0].name", is(notNullValue())))
                .andExpect(jsonPath("$[0].price", is(notNullValue())));
    }

    @Test
    void getProductById_withValidId_shouldReturnProduct() throws Exception {
        // First, get all products to extract an ID
        MvcResult result = mockMvc.perform(get("/api/products"))
                .andExpect(status().isOk())
                .andReturn();

        String content = result.getResponse().getContentAsString();
        List<Product> products = objectMapper.readValue(content, 
                objectMapper.getTypeFactory().constructCollectionType(List.class, Product.class));
        
        Long id = products.get(0).getId();

        // Now test with an ID that exists
        mockMvc.perform(get("/api/products/{id}", id))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id", is(id.intValue())));
    }

    @Test
    void getProductById_withInvalidId_shouldReturn404() throws Exception {
        mockMvc.perform(get("/api/products/999999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void createProduct_withValidProduct_shouldCreateAndReturnProduct() throws Exception {
        String productJson = objectMapper.writeValueAsString(testProduct);

        mockMvc.perform(post("/api/products")
                .contentType(MediaType.APPLICATION_JSON)
                .content(productJson))
                .andExpect(status().isCreated())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id", is(notNullValue())))
                .andExpect(jsonPath("$.name", is(testProduct.getName())))
                .andExpect(jsonPath("$.description", is(testProduct.getDescription())))
                .andExpect(jsonPath("$.price", is(testProduct.getPrice().doubleValue())))
                .andExpect(jsonPath("$.category", is(testProduct.getCategory())))
                .andExpect(jsonPath("$.stockQuantity", is(testProduct.getStockQuantity())));
    }

    @Test
    void createProduct_withInvalidProduct_shouldReturn400() throws Exception {
        // Create an invalid product with a null name
        testProduct.setName(null);
        String productJson = objectMapper.writeValueAsString(testProduct);

        mockMvc.perform(post("/api/products")
                .contentType(MediaType.APPLICATION_JSON)
                .content(productJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    void updateProduct_withValidProductAndId_shouldUpdateAndReturnProduct() throws Exception {
        // First, create a product
        testProduct.setName("Original Name");
        String productJson = objectMapper.writeValueAsString(testProduct);

        MvcResult createResult = mockMvc.perform(post("/api/products")
                .contentType(MediaType.APPLICATION_JSON)
                .content(productJson))
                .andExpect(status().isCreated())
                .andReturn();

        Product createdProduct = objectMapper.readValue(
                createResult.getResponse().getContentAsString(), Product.class);
        Long id = createdProduct.getId();

        // Now update the product
        createdProduct.setName("Updated Name");
        String updatedJson = objectMapper.writeValueAsString(createdProduct);

        mockMvc.perform(put("/api/products/{id}", id)
                .contentType(MediaType.APPLICATION_JSON)
                .content(updatedJson))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id", is(id.intValue())))
                .andExpect(jsonPath("$.name", is("Updated Name")));
    }

    @Test
    void updateProduct_withInvalidId_shouldReturn404() throws Exception {
        String productJson = objectMapper.writeValueAsString(testProduct);

        mockMvc.perform(put("/api/products/999999")
                .contentType(MediaType.APPLICATION_JSON)
                .content(productJson))
                .andExpect(status().isNotFound());
    }

    @Test
    void updateProduct_withInvalidProduct_shouldReturn400() throws Exception {
        // First get a valid ID
        MvcResult result = mockMvc.perform(get("/api/products"))
                .andExpect(status().isOk())
                .andReturn();

        String content = result.getResponse().getContentAsString();
        List<Product> products = objectMapper.readValue(content, 
                objectMapper.getTypeFactory().constructCollectionType(List.class, Product.class));
        
        Long id = products.get(0).getId();

        // Create an invalid product with a null name
        testProduct.setName(null);
        String productJson = objectMapper.writeValueAsString(testProduct);

        mockMvc.perform(put("/api/products/{id}", id)
                .contentType(MediaType.APPLICATION_JSON)
                .content(productJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    void deleteProduct_withValidId_shouldReturnNoContent() throws Exception {
        // First, create a product to delete
        testProduct.setName("Product to Delete");
        String productJson = objectMapper.writeValueAsString(testProduct);

        MvcResult createResult = mockMvc.perform(post("/api/products")
                .contentType(MediaType.APPLICATION_JSON)
                .content(productJson))
                .andExpect(status().isCreated())
                .andReturn();

        Product createdProduct = objectMapper.readValue(
                createResult.getResponse().getContentAsString(), Product.class);
        Long id = createdProduct.getId();

        // Now delete it
        mockMvc.perform(delete("/api/products/{id}", id))
                .andExpect(status().isNoContent());

        // Verify that the product does not exist
        mockMvc.perform(get("/api/products/{id}", id))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteProduct_withInvalidId_shouldReturn404() throws Exception {
        mockMvc.perform(delete("/api/products/999999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void getProductsByCategory_shouldReturnProductsInCategory() throws Exception {
        String category = "Electronics";

        mockMvc.perform(get("/api/products/categories/{category}", category))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$[0].category", equalToIgnoringCase(category)));
    }

    @Test
    void getProductsByCategory_withNonExistingCategory_shouldReturnEmptyList() throws Exception {
        mockMvc.perform(get("/api/products/categories/NonExistentCategory"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$", hasSize(0)));
    }
    
    @Test
    void createSampleProducts_shouldAddProductsToDb() throws Exception {
        // Verify that the constructor created the sample products
        mockMvc.perform(get("/api/products"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(3))));
    }
}
