ALTER TABLE `storage_colla_document_version`
ADD COLUMN `id` bigint NOT NULL AUTO_INCREMENT AFTER `FIRST`,
ADD COLUMN `snapshot_path` varchar(255) DEFAULT NULL AFTER `has_snapshot`,
ADD COLUMN `start_time` double DEFAULT NULL AFTER `updated_date`;