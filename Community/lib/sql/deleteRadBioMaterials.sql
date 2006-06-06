define studyId = &studyId;

--Delete all entries in RAD.BioMaterialMeasurement for that study:
DELETE RAD.BioMaterialMeasurement WHERE bio_material_id in
  (SELECT bio_material_id FROM RAD.StudyBiomaterial WHERE study_id = &studyId);

--Delete all entries in RAD.TreatmentParam for that study:
DELETE RAD.TreatmentParam WHERE treatment_id in
  (SELECT treatment_id FROM RAD.Treatment WHERE bio_material_id in
    (SELECT bio_material_id FROM RAD.StudyBiomaterial WHERE study_id = &studyId));

--Delete all entries in RAD.Treatment for that study:
Delete RAD.Treatment WHERE bio_material_id in
  (SELECT bio_material_id FROM RAD.StudyBiomaterial WHERE study_id = &studyId);

--Delete all entries in Study.BioMaterialCharacteristic for that study:
DELETE Study.BioMaterialCharacteristic where bio_material_id in
  (SELECT bio_material_id FROM RAD.StudyBiomaterial WHERE study_id = &studyId);

--Delete all entries in RAD.AssayLabeledExtract for that study:
--DELETE RAD.AssayLabeledExtract where assay_id in (SELECT assay_id FROM RAD.StudyAssay WHERE study_id = &studyId)
 --or
DELETE RAD.AssayLabeledExtract where labeled_extract_id in 
  (SELECT bio_material_id FROM RAD.StudyBiomaterial WHERE study_id = &studyId);

--Delete all entries in RAD.AssayBioMaterial for that study:
--DELETE RAD.AssayBioMaterial where assay_id in (SELECT assay_id FROM RAD.StudyAssay WHERE study_id = &studyId)
 --or
DELETE RAD.AssayBioMaterial where bio_material_id in 
  (SELECT bio_material_id FROM RAD.StudyBiomaterial WHERE study_id = &studyId);

--Delete all entries in RAD.StudyBioMaterial for that study:
--First query for all bio_material_id 's for this study and retain this list (@bio_material_ids) which you will subsequently need in order to delete all entries in Study.BioMaterialImp for this study.

CREATE TABLE TMP ( bio_material_id int );
INSERT INTO TMP SELECT bio_material_id FROM RAD.StudyBiomaterial WHERE study_id = &studyId;

--Delete from StudyBioMaterial
DELETE RAD.StudyBiomaterial WHERE study_id = &studyId;

--Finally, Delete ALL entries in Study.BioMaterialImp for that study:
DELETE Study.BioMaterialImp WHERE bio_material_id in 
  (SELECT bio_material_id from TMP);

DROP TABLE TMP;


