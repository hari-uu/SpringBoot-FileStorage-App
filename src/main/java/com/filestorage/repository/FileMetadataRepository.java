package com.filestorage.repository;

import com.filestorage.model.FileMetadata;
import com.filestorage.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface FileMetadataRepository extends JpaRepository<FileMetadata, Long> {
    List<FileMetadata> findByUser(User user);
    List<FileMetadata> findByUserOrderByUploadedAtDesc(User user);
    Optional<FileMetadata> findByIdAndUser(Long id, User user);
}
