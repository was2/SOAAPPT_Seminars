set sqlblanklines on

insert into sorappt ( 

  select students.saradap_pidm, '31-DEC-209'||substr(codes.meeting_code, -1,1), 
           1230, 1700, null, codes.meeting_code, null, null, null, sysdate
    from 
           -- pull pidms of students whose latest application 
           -- is a new first time applications or dual enrollment application
           -- for regular terms with an end date in the future 
           ( select distinct saradap_pidm
               from saradap outers
              where saradap_term_code_entry in ( select stvterm_code from stvterm 
                                                  where stvterm_end_date > sysdate
                                                    and substr(stvterm_code, 5, 2) 
                                                        in ('10', '20', '30', '40' ) )
                                                    
                and ( ( saradap_admt_code = 'FR' and saradap_styp_code = 'N' )
                      or ( saradap_admt_code = 'DE' and saradap_styp_code = 'D' ) )
                    
                and saradap_appl_no = ( select max(saradap_appl_no) from saradap inners
                                         where inners.saradap_pidm = outers.saradap_pidm
                                           and inners.saradap_term_code_entry 
                                               in ( select stvterm_code from stvterm 
                                                     where stvterm_end_date > sysdate
                                                       and substr(stvterm_code, 5, 2) 
                                                           in ('10', '20', '30', '40' ) ) 
                                      ) 
          ) students,

          ( select stvrecr_code meeting_code 
              from stvrecr 
             where stvrecr_code in ('001','002','003','004') 
          ) codes
         
          where not exists ( select 'nada' from sorappt 
                              where sorappt_pidm = students.saradap_pidm
                                and sorappt_recr_code = codes.meeting_code )
);

commit;

exit;