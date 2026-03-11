ALTER TABLE `card_contact`
ADD FULLTEXT KEY `card_contact_email_text_IDX` (`email_text`),
DROP INDEX `idx_contact_email_text`;