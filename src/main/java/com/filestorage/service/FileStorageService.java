package com.filestorage.service;

import com.filestorage.model.FileMetadata;
import com.filestorage.model.User;
import com.filestorage.repository.FileMetadataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;

@Service
public class FileStorageService {
    
    @Value("${file.upload-dir}")
    private String uploadDir;
    
    @Autowired
    private FileMetadataRepository fileMetadataRepository;
    
    public FileMetadata storeFile(MultipartFile file, User user) {
        // Create upload directory if it doesn't exist
        try {
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }
            
            // Generate unique filename
            String originalFilename = StringUtils.cleanPath(file.getOriginalFilename());
            String fileExtension = "";
            int dotIndex = originalFilename.lastIndexOf('.');
            if (dotIndex > 0) {
                fileExtension = originalFilename.substring(dotIndex);
            }
            String uniqueFilename = UUID.randomUUID().toString() + fileExtension;
            
            // Copy file to the target location
            Path targetLocation = uploadPath.resolve(uniqueFilename);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);
            
            // Save file metadata to database
            FileMetadata fileMetadata = new FileMetadata();
            fileMetadata.setFileName(uniqueFilename);
            fileMetadata.setOriginalFileName(originalFilename);
            fileMetadata.setFileType(file.getContentType());
            fileMetadata.setFileSize(file.getSize());
            fileMetadata.setFilePath(targetLocation.toString());
            fileMetadata.setUser(user);
            
            return fileMetadataRepository.save(fileMetadata);
            
        } catch (IOException ex) {
            throw new RuntimeException("Could not store file. Please try again!", ex);
        }
    }
    
    public Resource loadFileAsResource(Long fileId, User user) {
        try {
            FileMetadata fileMetadata = fileMetadataRepository.findByIdAndUser(fileId, user)
                    .orElseThrow(() -> new RuntimeException("File not found"));
            
            Path filePath = Paths.get(fileMetadata.getFilePath());
            Resource resource = new UrlResource(filePath.toUri());
            
            if (resource.exists() && resource.isReadable()) {
                return resource;
            } else {
                throw new RuntimeException("File not found or not readable");
            }
        } catch (Exception ex) {
            throw new RuntimeException("File not found", ex);
        }
    }
    
    public List<FileMetadata> getUserFiles(User user) {
        return fileMetadataRepository.findByUserOrderByUploadedAtDesc(user);
    }
    
    public void deleteFile(Long fileId, User user) {
        try {
            FileMetadata fileMetadata = fileMetadataRepository.findByIdAndUser(fileId, user)
                    .orElseThrow(() -> new RuntimeException("File not found"));
            
            // Delete physical file
            Path filePath = Paths.get(fileMetadata.getFilePath());
            Files.deleteIfExists(filePath);
            
            // Delete metadata from database
            fileMetadataRepository.delete(fileMetadata);
            
        } catch (IOException ex) {
            throw new RuntimeException("Could not delete file", ex);
        }
    }
    
    public FileMetadata getFileMetadata(Long fileId, User user) {
        return fileMetadataRepository.findByIdAndUser(fileId, user)
                .orElseThrow(() -> new RuntimeException("File not found"));
    }
}
