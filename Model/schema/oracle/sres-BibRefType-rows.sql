
/*                                                                                            */
/* sres-BibRefType-rows.sql                                                                   */
/*                                                                                            */
/* Populate sres.BibRefType, a controlled vocabulary of bibliographic reference types.        */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 20:42:32 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL sres-BibRefType-rows.log

SET ESCAPE '\';
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
INSERT INTO @oracle_sres@.BibRefType VALUES(1,'abstract',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:46',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(2,'archive',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:46',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(3,'audiotape',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:46',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(5,'book',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(6,'book review',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(7,'booklet',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(8,'CD-ROM',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(9,'chart',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(10,'computer file',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(11,'database',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(12,'demonstration',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(15,'film',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(16,'film strip',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(17,'leaflet',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(19,'manuscript',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(20,'microfiche',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(21,'microscope slides',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(23,'note',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(24,'obituary',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(25,'patent',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(26,'personal communication',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(27,'poem',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(28,'poster',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(29,'press release',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(30,'recording',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(31,'report',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(33,'slides',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(36,'T-shirt',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(37,'thesis',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(38,'transcript of broadcast',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(39,'unpublished',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(40,'video',NULL,'FlyBase',21,NULL,'2003-01-09 15:03:47',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(41,'addresses',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(42,'bibliography',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(43,'biography',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(44,'classical article',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(45,'clinical conference',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(46,'clinical trial',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(47,'clinical trial, phase i',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(48,'clinical trial, phase ii',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(49,'clinical trial, phase iii',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(50,'clinical trial, phase iv',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(51,'comment',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(52,'congresses',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(53,'consensus development conference',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(54,'consensus development conference, nih',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(55,'controlled clinical trial',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(56,'corrected and republished article',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(57,'dictionary',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(58,'directory',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(59,'duplicate publication',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(60,'editorial',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(61,'evaluation studies',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(62,'festschrift',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(63,'government publications',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(64,'guideline',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(65,'historical article',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(66,'interview',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(67,'journal article',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(68,'lectures',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(69,'legal cases',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(70,'legislation',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(71,'letter',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(72,'meta-analysis',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(73,'multicenter study',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(74,'news',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(75,'newspaper article',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(76,'overall',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(77,'patient education handout',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(78,'periodical index',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(79,'practice guideline',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(80,'published erratum',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(81,'randomized controlled trial',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(82,'retracted publication',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(83,'retraction of publication',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(84,'review',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(85,'review literature',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(86,'review of reported cases',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(87,'review, academic',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(88,'review, multicase',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(89,'review, tutorial',NULL,'MEDLINE',22,NULL,'2003-01-09 20:47:05',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_sres@.BibRefType VALUES(90,'online resource','A reference available online, e.g. a web page, web site, web-based publication, or any other network-accessible resource identifiable via a (hopefully) stable URL.  See also the entry for ''computer file'', which is a more specific (and likely outdated) term.','CBIL',NULL,NULL,'2003-01-09 23:40:14',1,1,1,1,1,0,1, 1, 1, 1);

/* 82 row(s) */


DROP SEQUENCE @oracle_sres@.BibRefType_SQ;
CREATE SEQUENCE @oracle_sres@.BibRefType_SQ START WITH 91;

COMMIT;
SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT
