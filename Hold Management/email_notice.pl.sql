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
   
l_notice_template varchar2(4000);
   
BEGIN
  
  select text
    into l_notice_template
    from mgccop.seminar_notices
   where label = 'notice01';
  
  
  FOR student in c_students LOOP

    DECLARE
      l_notice_text varchar2(4000);
      l_seminar_descs varchar2(4000);
      cursor c_seminar_descs (p_pidm varchar2) is
      select stvrecr_desc from stvrecr, sorappt
       where sorappt_pidm = p_pidm
         and sorappt_recr_code in ('001','002','003','004')          and sorappt_rslt_code is null
         and stvrecr_code = sorappt_recr_code;
    BEGIN
      FOR descrip in c_seminar_descs(student.pidm) LOOP
        l_seminar_descs := l_seminar_descs || descrip.stvrecr_desc || utl_tcp.crlf;
      END LOOP;
          
      l_notice_text := replace(l_notice_template, '<<name>>', person_info.f_get_fname(student.pidm));
      l_notice_text := replace(l_notice_text, '<<seminars>>', l_seminar_descs);
  
      mgccop.send_mail( p_to => 'drew.sawyer@mgccc.edu', --student_info.f_get_email( student.pidm )
                        p_from => 'some.guy@mgccc.edu',
                        p_subject => 'You have not attended required seminars!',
                        p_text_msg => l_notice_text,
                        p_smtp_host => 'mgcccmail.mgccc.edu' );
    END;
  END LOOP;

END;
   
