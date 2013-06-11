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

    
    and (  not exists ( select 'ug-credit' from shrlgpa
                                     where shrlgpa_pidm = sgbstdn_pidm
                                       and shrlgpa_levl_code = 'UG' )
           or ( exists ( select 'dual-enrolled' from sgbstdn inners
                          where inners.sgbstdn_pidm = sgbstdn.sgbstdn_pidm
                            and inners.sgbstdn_styp_code = 'D' ) 
                and 24 > ( select shrlgpa_hours_attempted
                             from shrlgpa
                            where shrlgpa_pidm = sgbstdn_pidm
                              and shrlgpa_levl_code = 'I'
                              and shrlgpa_
        )
    
    -- and have no transfer credits
    and not exists (select 'any' from shrtrce
                     where shrtrce_pidm = sgbstdn_pidm )
    
    -- are currently freshmen according to the banner api
    and 'FR' = SGKCLAS.F_CLASS_CODE(sgbstdn_pidm,'UG','999999')

);

select count(*) from sawyer.scratch
