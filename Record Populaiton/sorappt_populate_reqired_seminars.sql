set sqlblanklines on;

/* 
  Creates the appointment records to be inserted into SORAPPT
  that represent the 4 required seminars for new first-time freshmen;
  much of the logic catches small cases due to unreliable data entry.
*/

insert into sorappt ( 
  
  select students.pidm, '31-DEC-209'||substr(codes.meeting_code, -1,1), 
           1230, 1700, null, codes.meeting_code, null, null, null, sysdate
    from (  select sgbstdn_pidm pidm
              from sgbstdn,
              -- get latest learner record for all students by 
              -- joining to sgbstdn on max effective term code
              ( select sgbstdn_pidm pidm, max( sgbstdn_term_code_eff ) term
                  from sgbstdn 
                 group by sgbstdn_pidm ) latest_learner_rec,
              -- join to list of currently active terms
              ( select stvterm_code from stvterm 
                 where stvterm_end_date > sysdate
                   and substr(stvterm_code, 5, 2) in ('10', '20', '30', '40' ) )  current_terms 
                
              where sgbstdn_pidm = latest_learner_rec.pidm
                and sgbstdn_term_code_eff = latest_learner_rec.term
                and sgbstdn_term_code_eff = current_terms.stvterm_code
            
                -- only consider new first-time or currently dual-enrolled 
                and sgbstdn_styp_code in ( 'N', 'D' )
                -- sometimes new sgbstdn records reclassify students incorrectly, filter
                -- out students with returning, former, or transfer records in the past
                and not exists ( select 'non-first-timers' from sgbstdn inners
                                  where inners.sgbstdn_pidm = sgbstdn.sgbstdn_pidm
                                    and inners.sgbstdn_styp_code in ( 'R', 'F', 'T' ) )
                and ( sgbstdn_pidm not in ( select shrlgpa_pidm from shrlgpa
                                             where shrlgpa_levl_code = 'UG' )
                      or ( sgbstdn_pidm in ( select sgbstdn_pidm from sgbstdn inners
                                              where inners.sgbstdn_styp_code = 'D' ) 
                         )
                    )
                -- and have no transfer credits
                and not exists (select 'any' from shrtrce
                                 where shrtrce_pidm = sgbstdn_pidm )
                
                -- are currently freshmen according to the banner api
                and 'FR' = SGKCLAS.F_CLASS_CODE(sgbstdn_pidm,'UG','999999')    
          ) students,


          ( select stvrecr_code meeting_code 
              from stvrecr 
             where stvrecr_code in ('001','002','003','004') 
          ) codes
         
    where not exists ( select 'nada' from sorappt 
                        where sorappt_pidm = students.pidm
                          and sorappt_recr_code = codes.meeting_code )
);

commit;

exit;

-----------------------------------------------------------------
-- old approach for student view, used application records
-----------------------------------------------------------------
--           -- pull pidms of students whose latest application 
--           -- is a new first time applications or dual enrollment application
--           -- for regular terms with an end date in the future 
--           ( select distinct saradap_pidm
--               from saradap outers
--              where saradap_term_code_entry in ( select stvterm_code from stvterm 
--                                                  where stvterm_end_date > sysdate
--                                                    and substr(stvterm_code, 5, 2) 
--                                                        in ('10', '20', '30', '40' ) )
--                                                    
--                and ( ( saradap_admt_code = 'FR' and saradap_styp_code = 'N' )
--                      or ( saradap_admt_code = 'DE' and saradap_styp_code = 'D' ) )
--                    
--                and saradap_appl_no = ( select max(saradap_appl_no) from saradap inners
--                                         where inners.saradap_pidm = outers.saradap_pidm
--                                           and inners.saradap_term_code_entry 
--                                               in ( select stvterm_code from stvterm 
--                                                     where stvterm_end_date > sysdate
--                                                       and substr(stvterm_code, 5, 2) 
--                                                           in ('10', '20', '30', '40' ) ) 
--                                      ) 