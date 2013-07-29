DECLARE

CURSOR c_students IS

-- noncompliant_students are students who have not yet attended all the seminars;
-- using a 'with' clause because the subquery is used multiple times
with noncompliant_students as 
     ( select distinct sorappt_pidm pidm
         from sorappt
        where sorappt_recr_code in ('001','002','003','004')
          and sorappt_rslt_code is null )
     
select noncompliant_students.pidm pidm
  
  from noncompliant_students,
      
       -- inline view: credit hours rolled to academic history
       (  select shrtckg_pidm pidm, sum(shrtckg.shrtckg_credit_hours) hours
            from shrtckg, shrtckl, noncompliant_students,
                 (  select shrtckg_pidm pidm, shrtckg_term_code term, 
                           shrtckg_tckn_seq_no tckn_seq, max(shrtckg_seq_no) seq
                      from shrtckg, noncompliant_students
                     where shrtckg_pidm = noncompliant_students.pidm
                     group by shrtckg_pidm, shrtckg_term_code, shrtckg_tckn_seq_no
                 ) max_tckg
           where shrtckg_pidm = noncompliant_students.pidm
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
         
       -- inline view: credit hrs in progress
       ( select sfrstcr_pidm pidm, sum(sfrstcr_credit_hr) hours
           from sfrstcr, noncompliant_students
          where sfrstcr_pidm = noncompliant_students.pidm
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

 where rolled.pidm = noncompliant_students.pidm
   and inprog.pidm = noncompliant_students.pidm
   and rolled.hours + inprog.hours >= 24;
   
BEGIN
  
  FOR student in c_students LOOP

    DECLARE
      l_template_params mgccop.mail_via_templates.TemplateParams;
      l_seminar_descs varchar2(500) :=  null;
      l_return_email varchar2(100) := 'do.not.reply@mgccc.edu';
      
      cursor c_seminar_descs (p_pidm varchar2) is
      select stvrecr_desc from stvrecr, sorappt
       where sorappt_pidm = p_pidm
         and sorappt_recr_code in ('001','002','003','004')          
         and sorappt_rslt_code is null
         and stvrecr_code = sorappt_recr_code;
         
    BEGIN
      --build list of seminar descriptions for inclusion in email
      FOR descrip in c_seminar_descs(student.pidm) LOOP
        l_seminar_descs := l_seminar_descs || descrip.stvrecr_desc || utl_tcp.crlf;
      END LOOP;
      
      l_template_params := 
        mgccop.mail_via_templates.TemplateParams( person_info.f_get_fname(student.pidm),
                                                  l_seminar_descs );
      
      -- l_return_email := 
      
      mgccop.mail_via_templates.mail_template( '&1', 
                                               'drew.sawyer@mgccc.edu', --student_info.f_get_email(student.pidm)
                                               student_info.f_get_campus(student.pidm, '209910'),
                                               l_template_params );
    END; 
  
  END LOOP;

END;
   
