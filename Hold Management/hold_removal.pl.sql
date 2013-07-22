DECLARE

CURSOR c_invalid_holds IS
-- rowids of seminar holds who now have attended all seminars
select rowid
  from sprhold  
 where sprhold_hldd_code = '99'
   and exists ( select 'seminar1-attended'
                  from sorappt
                 where sorappt_recr_code = '001'
                   and sorappt_rslt_code = 'ATT' )
  and exists ( select 'seminar2-attended'
                  from sorappt
                 where sorappt_recr_code = '002'
                   and sorappt_rslt_code = 'ATT' )
  and exists ( select 'seminar3-attended'
                  from sorappt
                 where sorappt_recr_code = '003'
                   and sorappt_rslt_code = 'ATT' )
  and exists ( select 'seminar4-attended'
                  from sorappt
                 where sorappt_recr_code = '004'
                   and sorappt_rslt_code = 'ATT' );
   
BEGIN

  for hold in c_invalid_holds loop
    gb_hold.p_delete( p_rowid => rowidtochar(hold.rowid) );
  end loop;

END;