DECLARE
 PROCEDURE my_proc IS
 BEGIN
  DECLARE
   myseq CLOB;
   myseqid NUMBER(12);
   CURSOR aaseq IS
   SELECT aa_sequence_id, sequence from translatedaasequence
   WHERE sequence is not null;
  BEGIN
   OPEN aaseq;
   FETCH aaseq INTO myseqid, myseq; 

     WHILE aaseq%FOUND
     LOOP
       IF (DBMS_LOB.INSTR(myseq, '*') != 0) 
       THEN
         INSERT INTO aaseqs_with_stops VALUES(myseqid);
       END IF;
       FETCH aaseq INTO myseqid, myseq;
     END LOOP;
   CLOSE aaseq;
  END;
 END my_proc;
BEGIN
  my_proc();
END;
