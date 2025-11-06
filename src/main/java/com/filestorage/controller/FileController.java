package com.filestorage.controller;

import com.filestorage.model.FileMetadata;
import com.filestorage.model.User;
import com.filestorage.service.FileStorageService;
import com.filestorage.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
public class FileController {
    
    @Autowired
    private FileStorageService fileStorageService;
    
    @Autowired
    private UserService userService;
    
    @GetMapping("/dashboard")
    public String showDashboard(Authentication authentication, Model model) {
        User user = userService.findByUsername(authentication.getName());
        List<FileMetadata> files = fileStorageService.getUserFiles(user);
        
        model.addAttribute("username", user.getUsername());
        model.addAttribute("files", files);
        
        return "dashboard";
    }
    
    @PostMapping("/upload")
    public String uploadFile(@RequestParam("file") MultipartFile file,
                            Authentication authentication,
                            RedirectAttributes redirectAttributes) {
        try {
            if (file.isEmpty()) {
                redirectAttributes.addFlashAttribute("error", "Please select a file to upload");
                return "redirect:/dashboard";
            }
            
            User user = userService.findByUsername(authentication.getName());
            fileStorageService.storeFile(file, user);
            
            redirectAttributes.addFlashAttribute("message", 
                    "File uploaded successfully: " + file.getOriginalFilename());
            
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("error", 
                    "Failed to upload file: " + e.getMessage());
        }
        
        return "redirect:/dashboard";
    }
    
    @GetMapping("/download/{fileId}")
    public ResponseEntity<Resource> downloadFile(@PathVariable Long fileId,
                                                 Authentication authentication) {
        try {
            User user = userService.findByUsername(authentication.getName());
            FileMetadata fileMetadata = fileStorageService.getFileMetadata(fileId, user);
            Resource resource = fileStorageService.loadFileAsResource(fileId, user);
            
            String contentType = fileMetadata.getFileType();
            if (contentType == null) {
                contentType = "application/octet-stream";
            }
            
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION, 
                            "attachment; filename=\"" + fileMetadata.getOriginalFileName() + "\"")
                    .body(resource);
                    
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    @PostMapping("/delete/{fileId}")
    public String deleteFile(@PathVariable Long fileId,
                            Authentication authentication,
                            RedirectAttributes redirectAttributes) {
        try {
            User user = userService.findByUsername(authentication.getName());
            fileStorageService.deleteFile(fileId, user);
            
            redirectAttributes.addFlashAttribute("message", "File deleted successfully");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("error", "Failed to delete file: " + e.getMessage());
        }
        
        return "redirect:/dashboard";
    }
}
