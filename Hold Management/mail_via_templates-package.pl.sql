/*
  Drew Sawyer - 7/29/13
  
  Package contains types and procedures for sending emails
  using templates stored in the mgccop.email_templates table.
  
  TemplateParams is a varray used by client procedures to
  send in a list of varchar2's to replace the templates markers
  encountered in the templase (eg. <<1>>, <<2>>...). They are
  used in the order they are sent.
  
  mail_template formats the template using the TemplateParams parameter
  and emails the result using p_to_address and p_return_address
*/

CREATE OR REPLACE 
PACKAGE MGCCOP.MAIL_VIA_TEMPLATES AS 

  TYPE TemplateParams IS VARRAY(100) of VARCHAR2(500);
  
  PROCEDURE mail_template ( p_template_name in varchar2,
                            p_to_address in varchar2,
                            p_from_address in varchar2,
                            p_template_params in TemplateParams default null );

END MAIL_VIA_TEMPLATES;

CREATE OR REPLACE
PACKAGE BODY mgccop.MAIL_VIA_TEMPLATES AS

  PROCEDURE mail_template ( p_template_name in varchar2,
                            p_to_address in varchar2,
                            p_from_address in varchar2,
                            p_template_params in TemplateParams default null ) AS
  
    l_template_text varchar2(4000);
    l_subject varchar2(200);
  
  BEGIN
     
    select text, subject
      into l_template_text, l_subject
      from mgccop.email_templates
     where mgccop.email_templates.label = p_template_name;
     
    if p_template_params is not null and p_template_params.count > 0 then
      for counter in 1..p_template_params.count loop
        l_template_text := replace(l_template_text, '<<' || counter || '>>', p_template_params(counter));
      end loop;
    end if;
    
    mgccop.send_mail( p_to => 'drew.sawyer@mgccc.edu', --student_info.f_get_email( student.pidm )
                      p_from => 'some.guy@mgccc.edu',
                      p_subject => l_subject,
                      p_text_msg => l_template_text,
                      p_smtp_host => 'mgcccmail.mgccc.edu' );
     
  END mail_template;

END MAIL_VIA_TEMPLATES;