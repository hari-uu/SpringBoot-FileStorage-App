package com.filestorage.service;

import com.filestorage.model.FileMetadata;
import com.filestorage.model.User;
import com.filestorage.repository.FileMetadataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@Service
public class FileStorageService {
    
    @Autowired
    private FileMetadataRepository fileMetadataRepository;
    
    @Autowired
    private S3Service s3Service;
    
    public FileMetadata storeFile(MultipartFile file, User user) {
        try {
            // Upload to S3
            String s3FileName = s3Service.uploadFile(file);
            
            // Save metadata to database
            FileMetadata fileMetadata = new FileMetadata();
            fileMetadata.setFileName(s3FileName);
            fileMetadata.setOriginalFileName(StringUtils.cleanPath(file.getOriginalFilename()));
            fileMetadata.setFileType(file.getContentType());
            fileMetadata.setFileSize(file.getSize());
            // Store the full S3 URL for reference, or just the key if preferred. 
            // Using logic from S3Service.getFileUrl for consistency.
            fileMetadata.setFilePath(s3Service.getFileUrl(s3FileName)); 
            fileMetadata.setUser(user);
            
            return fileMetadataRepository.save(fileMetadata);
            
        } catch (IOException ex) {
            throw new RuntimeException("Could not store file to S3. Please try again!", ex);
        }
    }
    
    public Resource loadFileAsResource(Long fileId, User user) {
        try {
            FileMetadata fileMetadata = fileMetadataRepository.findByIdAndUser(fileId, user)
                    .orElseThrow(() -> new RuntimeException("File not found"));
            
            // Download bytes from S3
            byte[] data = s3Service.downloadFile(fileMetadata.getFileName());
            
            return new ByteArrayResource(data);
            
        } catch (Exception ex) {
            throw new RuntimeException("File not found or could not download from S3", ex);
        }
    }
    
    public List<FileMetadata> getUserFiles(User user) {
        return fileMetadataRepository.findByUserOrderByUploadedAtDesc(user);
    }
    
    public void deleteFile(Long fileId, User user) {
        try {
            FileMetadata fileMetadata = fileMetadataRepository.findByIdAndUser(fileId, user)
                    .orElseThrow(() -> new RuntimeException("File not found"));
            
            // Delete from S3
            s3Service.deleteFile(fileMetadata.getFileName());
            
            // Delete metadata from database
            fileMetadataRepository.delete(fileMetadata);
            
        } catch (Exception ex) {
            throw new RuntimeException("Could not delete file", ex);
        }
    }
    
    public FileMetadata getFileMetadata(Long fileId, User user) {
        return fileMetadataRepository.findByIdAndUser(fileId, user)
                .orElseThrow(() -> new RuntimeException("File not found"));
    }
}
