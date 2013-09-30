create or replace 
TRIGGER MGCCOP.REMOVE_SUCCESS_SEMINAR_HOLDS 
AFTER UPDATE OF SORAPPT_RSLT_CODE ON SATURN.SORAPPT 

/*
  Drew Sawyer 9/2013
  Trigger to remove success seminar attendance holds (code 99) for students
  when all 4 seminars are attended
*/

DECLARE

CURSOR c_invalid_holds IS
-- rowids of seminar holds for students who now have attended all seminars
select rowid
  from sprhold  
 where sprhold_hldd_code = '99'
   and exists ( select 'seminar1-attended'
                  from sorappt
                 where sorappt_pidm = sprhold_pidm
                   and sorappt_recr_code = '001'
                   and sorappt_rslt_code = 'ATT' )
   and exists ( select 'seminar2-attended'
                  from sorappt
                 where sorappt_pidm = sprhold_pidm
                   and sorappt_recr_code = '002'
                   and sorappt_rslt_code = 'ATT' )
   and exists ( select 'seminar3-attended'
                  from sorappt
                 where sorappt_pidm = sprhold_pidm
                   and sorappt_recr_code = '003'
                   and sorappt_rslt_code = 'ATT' )
   and exists ( select 'seminar4-attended'
                  from sorappt
                 where sorappt_pidm = sprhold_pidm
                   and sorappt_recr_code = '004'
                   and sorappt_rslt_code = 'ATT' );
   
BEGIN

--removes each invalid hold
  for hold in c_invalid_holds loop
    gb_hold.p_delete( p_rowid => rowidtochar(hold.rowid) );
  end loop;

END;