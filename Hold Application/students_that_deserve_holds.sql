select person_info.f_get_id(scratch.pidm), scratch.pidm, 
       rolled.hours rolled, inprog.hours inprog,
       rolled.hours + inprog.hours total
  
  from scratch,
  
       -- credit hours rolled to academic history
       (  select shrtckg_pidm pidm, sum(shrtckg.shrtckg_credit_hours) hours
            from shrtckg, shrtckl,
                 (  select shrtckg_pidm pidm, shrtckg_term_code term, 
                           shrtckg_tckn_seq_no tckn_seq, max(shrtckg_seq_no) seq
                      from shrtckg
                     where shrtckg_pidm in (select pidm from scratch)
                     group by shrtckg_pidm, shrtckg_term_code, shrtckg_tckn_seq_no
                 ) max_tckg
           where shrtckg_pidm in ( select pidm from scratch )
             and shrtckg_pidm = max_tckg.pidm
             and shrtckg_term_code = max_tckg.term
             and shrtckg_tckn_seq_no = max_tckg.tckn_seq
             and shrtckg_seq_no = max_tckg.seq
             and shrtckl_pidm = shrtckg_pidm
            
             and shrtckl_term_code = shrtckg_term_code
             and shrtckl_tckn_seq_no = shrtckg_tckn_seq_no
             and shrtckl.shrtckl_levl_code = 'UG'
           group by shrtckg_pidm
       ) rolled,
         
       -- credit hrs in progress
       ( select sfrstcr_pidm pidm, sum(sfrstcr_credit_hr) hours
           from sfrstcr
          where sfrstcr_pidm in ( select pidm from scratch )
          
            and sfrstcr.sfrstcr_levl_code = 'UG'
            and sfrstcr_grde_date is null
            and sfrstcr.sfrstcr_rsts_code in ( select stvrsts_code
                                                 from stvrsts
                                                where stvrsts.stvrsts_incl_sect_enrl = 'Y' )
            and sfrstcr_term_code in ( select stvterm_code from stvterm 
                                      where stvterm_end_date > sysdate
                                        and substr(stvterm_code, 5, 2) 
                                            in ('10', '20', '30', '40' ) )
          group by sfrstcr_pidm
       ) inprog
        
 where rolled.pidm = scratch.pidm
   and inprog.pidm = rolled.pidm