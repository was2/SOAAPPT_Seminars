/*
Drew Sawyer
Aug. 2013
Used in ApEx applicaion as a page process.
*/

DECLARE

  l_test_mode boolean := false;

  CURSOR c_students IS

  -- noncompliant_students are students who have not yet attended all the 
  -- seminars but have not recieved a seminar hold yet.
  -- using a 'with' clause because the subquery is used multiple times
  with noncompliant_students as 
       ( select distinct sorappt_pidm pidm
           from sorappt
          where sorappt_recr_code in ('001','002','003','004')
            and sorappt_rslt_code is null
            and not exists ( select 'already-has-hold'
                               from sprhold
                              where sprhold_pidm = sorappt_pidm
                                and sprhold_hldd_code = '99' )
       )
       
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
  
 where rolled.pidm (+) = noncompliant_students.pidm
   and inprog.pidm (+) = noncompliant_students.pidm
   and nvl(rolled.hours, 0) + nvl(inprog.hours, 0) >= 24;

  l_return_address_PK varchar2(100) := 'heather.edwards@mgccc.edu';
  l_return_address_JD varchar2(100) := 'stephanie.roy@mgccc.edu';
  l_return_address_JC varchar2(100) := 'pamela.ladner@mgccc.edu';
  l_return_address_GC varchar2(100) := 'cheryl.bond@mgccc.edu';
  
  l_seminar_hold_code CONSTANT varchar2(2) := '99';

BEGIN
  
  FOR student in c_students LOOP

    DECLARE
      l_template_params mgccop.mail_via_templates.TemplateParams;
      l_seminar_descs varchar2(500) :=  null;
      l_return_address varchar2(100) := 'do.not.reply@mgccc.edu';
      l_rowid varchar2(18); -- required by hold creation proc.
      
      -- gets descriptions the seminars the student lacks
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
      
      -- build list of string to use in template replacements: first name and 
      -- list of seminars the student lacks
      l_template_params := 
        mgccop.mail_via_templates.TemplateParams( person_info.f_get_fname(student.pidm),
                                                  l_seminar_descs );
      
      -- determine which return email to use based on campus
      case student_info.f_get_campus(student.pidm, '999999')
        when 2 then l_return_address := l_return_address_PK;
        when 3 then l_return_address := l_return_address_JD;
        when 4 then l_return_address := l_return_address_JC;
        when 5 then l_return_address := l_return_address_GC;
      else
        l_return_address := 'do.not.reply@mgccc.edu';
      end case;

      --send emails; if we are sending the 4th notice, apply holds
      if not l_test_mode then
        mgccop.mail_via_templates.mail_template( '&REQUEST.', 
                                                 'drew.sawyer@mgccc.edu', --student_info.f_get_email(student.pidm)
                                                 l_return_address,
                                                 l_template_params );
                                                 
        if '&REQUEST.' = 'seminar_notice_4' then
--          gb_hold.p_create(p_pidm => student.pidm, p_hldd_code => l_seminar_hold_code, 
--                           p_user => 'PLUTO', p_from_date => sysdate, p_to_date => '31-DEC-2099',
--                           p_release_ind => 'N', p_rowid_out => l_rowid);
          dbms_output.put_line( to_char(person_info.f_get_id(student.pidm)) || ' - added seminar hold');
        end if;
        
      end if;
      
    END; 
  
  END LOOP;

END;