import 'package:integration_test/integration_test.dart';

import 'admin_doctors_review_flow_test.dart' as admin_doctors_review_flow;
import 'admin_shell_flow_test.dart' as admin_shell_flow;
import 'admin_user_detail_flow_test.dart' as admin_user_detail_flow;
import 'auth_flow_test.dart' as auth_flow;
import 'doctor_profile_edit_flow_test.dart' as doctor_profile_edit_flow;
import 'doctor_shell_flow_test.dart' as doctor_shell_flow;
import 'forgot_password_flow_test.dart' as forgot_password_flow;
import 'forgot_password_navigation_flow_test.dart'
    as forgot_password_navigation_flow;
import 'login_empty_validation_flow_test.dart' as login_empty_validation_flow;
import 'login_form_input_flow_test.dart' as login_form_input_flow;
import 'patient_dashboard_overview_flow_test.dart'
    as patient_dashboard_overview_flow;
import 'patient_delete_account_navigation_flow_test.dart'
    as patient_delete_account_navigation_flow;
import 'patient_diary_history_flow_test.dart' as patient_diary_history_flow;
import 'patient_diary_qr_share_flow_test.dart' as patient_diary_qr_share_flow;
import 'patient_education_article_flow_test.dart'
    as patient_education_article_flow;
import 'patient_emergency_contacts_flow_test.dart'
    as patient_emergency_contacts_flow;
import 'patient_health_ml_navigation_flow_test.dart'
    as patient_health_ml_navigation_flow;
import 'patient_medication_flow_test.dart' as patient_medication_flow;
import 'patient_medication_lifecycle_test.dart'
    as patient_medication_lifecycle_flow;
import 'patient_medication_manage_detail_flow_test.dart'
    as patient_medication_manage_detail_flow;
import 'patient_profile_edit_flow_test.dart' as patient_profile_edit_flow;
import 'patient_shell_flow_test.dart' as patient_shell_flow;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  auth_flow.main();
  forgot_password_flow.main();
  forgot_password_navigation_flow.main();
  login_empty_validation_flow.main();
  login_form_input_flow.main();
  patient_shell_flow.main();
  patient_medication_flow.main();
  patient_medication_lifecycle_flow.main();
  patient_diary_history_flow.main();
  patient_profile_edit_flow.main();
  patient_emergency_contacts_flow.main();
  patient_education_article_flow.main();
  patient_dashboard_overview_flow.main();
  patient_health_ml_navigation_flow.main();
  patient_delete_account_navigation_flow.main();
  patient_diary_qr_share_flow.main();
  patient_medication_manage_detail_flow.main();
  doctor_shell_flow.main();
  doctor_profile_edit_flow.main();
  admin_shell_flow.main();
  admin_doctors_review_flow.main();
  admin_user_detail_flow.main();
}
