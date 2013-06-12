drop table sawyer.scratch;
create table sawyer.scratch as (

select sgbstdn_pidm pidm
              from sgbstdn,
              -- get latest record for all students by 
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

);

select count(*) from sawyer.scratch;

select sfrstcr_pidm, sum(sfrstcr_bill_hr),
                     sum(sfrstcr_credit_hr),
                     sum(shrlgpa_gpa_hours),
                     sum(shrlgpa_hours_attempted),
                     sum(shrlgpa_hours_earned),
                     sum(shrlgpa_hours_passed)
  from sfrstcr, scratch, shrlgpa
 where sfrstcr_pidm = scratch.pidm
   and shrlgpa_pidm = sfrstcr_pidm
   and shrlgpa_levl_code = 'UG'
   and shrlgpa.shrlgpa_gpa_type_ind = 'I'
   --and sfrstcr_grde_date is not null
group by sfrstcr_pidm;


select pidm, sum (hours) hours from (
select shrtckg_pidm pidm, shrtckg_hours_attempted hours --, sfrstcr_term_code, sfrstcr_credit_hr
  from shrtckg, shrtckl
 where shrtckg_pidm in ( select pidm from scratch )
   and shrtckl_pidm = shrtckg_pidm
  
   and shrtckl_term_code = shrtckg_term_code
   and shrtckl_tckn_seq_no = shrtckg_tckn_seq_no
   and shrtckl.shrtckl_levl_code = 'UG'
 
 union
 
 select sfrstcr_pidm, sfrstcr_credit_hr
   from sfrstcr
   where sfrstcr_pidm in ( select pidm from scratch )
  
    and sfrstcr.sfrstcr_levl_code = 'UG'
    and sfrstcr_term_code in ( select stvterm_code from stvterm 
                              where stvterm_end_date > sysdate
                                and substr(stvterm_code, 5, 2) 
                                    in ('10', '20', '30', '40' ) )
) group by pidm order by hours desc