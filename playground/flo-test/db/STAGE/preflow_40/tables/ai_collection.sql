CREATE TABLE `ai_collection` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `last_updated` double DEFAULT NULL,
  `collection_id` bigint DEFAULT NULL,
  `last_long_summary` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `total_event` int DEFAULT NULL,
  `total_note` int DEFAULT NULL,
  `total_todo` int DEFAULT NULL,
  `learn_from_last_note_id` int DEFAULT NULL,
  `learn_from_last_todo_id` int DEFAULT NULL,
  `learn_from_last_event_id` int DEFAULT NULL,
  `last_short_summary` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  PRIMARY KEY (`id`),
  KEY `ai_collection_collection_id_IDX` (`collection_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1