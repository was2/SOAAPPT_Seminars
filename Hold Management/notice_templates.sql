update MGCCOP.email_templates
set text = 'Dear <<1>>,

Pre-registration is approaching and we have noticed that you have not completed 
your Student Success Seminar requirements.  These seminars are offered on all
campuses and at a variety of times in order to enhance attendance.  Please 
attend these seminars as soon as possible.  Upon the start of pre-registration 
holds will be placed on accounts for any students who have not completed the
seminar.  This hold will prevent you from being able to register for future 
classes at Mississippi Gulf Coast Community College until the Student Success 
Seminar requirements are complete.  Please contact the Student Success Seminar 
Coordinator at your campus location for a list of upcoming seminars, times, 
and locations and attend the following seminars prior the start of 
pre-registration to avoid a hold being placed on your account:

<<2>>
Thank you.',
subject = 'Sutdent Success Seminars'

where label = 'seminar_notice_1';


update MGCCOP.email_templates
set text = 'Dear <<1>>,

Pre-registration is approaching and we have noticed that you have not completed 
your Student Success Seminar requirements.  These seminars are offered on all
campuses and at a variety of times in order to enhance attendance.  Please 
attend these seminars as soon as possible.  Upon the start of pre-registration 
holds will be placed on accounts for any students who have not completed the
seminar.  This hold will prevent you from being able to register for future 
classes at Mississippi Gulf Coast Community College until the Student Success 
Seminar requirements are complete.  Please contact the Student Success Seminar 
Coordinator at your campus location for a list of upcoming seminars, times, 
and locations and attend the following seminars prior the start of 
pre-registration to avoid a hold being placed on your account:

<<2>>
Keep in mind that seminar offerings at this point will be limited so please act 
now. 

Thank you.',
subject = 'Sutdent Success Seminars'

where label = 'seminar_notice_2';

update MGCCOP.email_templates
set text = 'Dear <<1>>,

Pre-registration is approaching and we have noticed that you have not completed 
your Student Success Seminar requirements.  These seminars are offered on all
campuses and at a variety of times in order to enhance attendance.  Please 
attend these seminars as soon as possible.  Upon the start of pre-registration 
holds will be placed on accounts for any students who have not completed the
seminar.  This hold will prevent you from being able to register for future 
classes at Mississippi Gulf Coast Community College until the Student Success 
Seminar requirements are complete.  Please contact the Student Success Seminar 
Coordinator at your campus location for a list of upcoming seminars, times, 
and locations and attend the following seminars prior the start of 
pre-registration to avoid a hold being placed on your account:

<<2>>
Keep in mind that seminar offerings at this point will be limited so please act 
now.  Contact the Student Success Seminar Coordinator on your campus in writing
if you have extenuating circumstances that need to be considered in order to 
appeal the hold. 

Thank you.',
subject = 'Sutdent Success Seminars'

where label = 'seminar_notice_3';

update MGCCOP.email_templates
set text = 'Dear <<1>>,

A registration hold has been placed on your account.  This hold will be lifted
upon completion of the required Student Success Seminars.  If you would like to
have the hold lifted, please attend the following seminars at your earliest
convenience: 

<<2>>
Upon completion the hold will be removed from your account and you
will be able to register for classes.  Please contact the Student Success
Coordinator at your campus if you have questions about your seminar completion
or need additional assistance with the Student Success Seminar.  Contact the
Student Success Seminar Coordinator on your campus in writing if you have
extenuating circumstances that need to be considered in order to appeal the
hold.  

Thank you.',
subject = 'Registration HOLD!'

where label = 'seminar_notice_4';