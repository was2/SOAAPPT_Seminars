DECLARE

CURSOR c_students IS
-- pidms with unattended seminars
with unattended_seminars as
     ( select distinct sorappt_pidm pidm
         from sorappt
        where sorappt_recr_code in ('001','002','003','004')
          and sorappt_rslt_code is null )
     
select unattended_seminars.pidm pidm
  
  from unattended_seminars,
       -- credit hours rolled to academic history
       (  select shrtckg_pidm pidm, sum(shrtckg.shrtckg_credit_hours) hours
            from shrtckg, shrtckl, unattended_seminars,
                 (  select shrtckg_pidm pidm, shrtckg_term_code term, 
                           shrtckg_tckn_seq_no tckn_seq, max(shrtckg_seq_no) seq
                      from shrtckg, unattended_seminars
                     where shrtckg_pidm = unattended_seminars.pidm
                     group by shrtckg_pidm, shrtckg_term_code, shrtckg_tckn_seq_no
                 ) max_tckg
           where shrtckg_pidm = unattended_seminars.pidm
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
           from sfrstcr, unattended_seminars
          where sfrstcr_pidm = unattended_seminars.pidm
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

 where rolled.pidm = unattended_seminars.pidm
   and inprog.pidm = unattended_seminars.pidm
   and rolled.hours + inprog.hours >= 24;

   l_seminar_hold_code CONSTANT varchar2(2) := '99';

   l_holds gb_hold.hold_ref;
   l_a_hold gb_hold.hold_rec;
   l_seminar_hold_exists boolean;
   l_rowid varchar2(18);
   
BEGIN

  for student in c_students loop
    l_holds := gb_hold.f_query_all(student.pidm);
    l_seminar_hold_exists := false;
    
    loop
      fetch l_holds into l_a_hold;
      exit when l_holds%notfound;
      if (l_a_hold.r_hldd_code = '99') then l_seminar_hold_exists := true; end if;
    end loop;
    
    close l_holds;
    
    if not l_seminar_hold_exists then
      gb_hold.p_create(p_pidm => student.pidm, p_hldd_code => l_seminar_hold_code, 
                       p_user => 'PLUTO', p_from_date => sysdate, p_to_date => '31-DEC-2099',
                       p_release_ind => 'N', p_rowid_out => l_rowid);
      dbms_output.put_line( to_char(person_info.f_get_id(student.pidm)) || ' - added seminar hold');
    else
      dbms_output.put_line(to_char(person_info.f_get_id(student.pidm)) || ' - hold exists');
    end if;
  end loop;
  
END;